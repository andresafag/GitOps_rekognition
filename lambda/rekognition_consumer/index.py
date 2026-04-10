import json
import boto3
import urllib.parse
import os
from datetime import datetime

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')


def handler(event, context):
    print('Received SQS event', json.dumps(event))

    for record in event.get('Records', []):
        body = record.get('body')
        try:
            message = json.loads(body)
        except Exception as error:
            print('Unable to parse SQS record body', error)
            continue

        s3_records = message.get('Records', [])
        if not s3_records:
            print('Non-S3 event passed from SQS', message)
            continue

        s3_event = s3_records[0].get('s3')
        if not s3_event:
            print('Non-S3 event passed from SQS', message)
            continue

        bucket_name = s3_event['bucket']['name']
        object_key = urllib.parse.unquote_plus(s3_event['object']['key'])

        print('Processing object', bucket_name, object_key)

        params = {
            'Image': {
                'S3Object': {
                    'Bucket': bucket_name,
                    'Name': object_key,
                }
            },
            'MaxLabels': 10,
            'MinConfidence': 75,
        }

        try:
            result = rekognition.detect_labels(**params)
            print('Rekognition result:', json.dumps(result, indent=2, default=str))

            # Store results in S3
            result_key = f"results/{object_key.replace('/', '-')}.json"
            result_data = {
                'originalImage': object_key,
                'timestamp': datetime.utcnow().isoformat(),
                'labels': result.get('Labels', []),
                'responseMetadata': result.get('ResponseMetadata', {})
            }

            s3.put_object(
                Bucket=bucket_name,
                Key=result_key,
                Body=json.dumps(result_data, indent=2, default=str),
                ContentType='application/json'
            )
            print(f'Stored Rekognition results to s3://{bucket_name}/{result_key}')

        except Exception as error:
            print(f'Rekognition detect_labels failed: {error}')
            # Store error information
            error_key = f"results/errors/{object_key.replace('/', '-')}.json"
            error_data = {
                'originalImage': object_key,
                'timestamp': datetime.utcnow().isoformat(),
                'error': str(error)
            }
            try:
                s3.put_object(
                    Bucket=bucket_name,
                    Key=error_key,
                    Body=json.dumps(error_data, indent=2),
                    ContentType='application/json'
                )
            except Exception as s3_error:
                print(f'Failed to store error log: {s3_error}')

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Processed SQS batch.'})
    }
