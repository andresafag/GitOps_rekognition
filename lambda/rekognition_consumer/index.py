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

        detection_mode = 'labels'
        try:
            metadata = s3.head_object(Bucket=bucket_name, Key=object_key).get('Metadata', {})
            detection_mode = metadata.get('detection-mode', detection_mode)
        except Exception as metadata_error:
            print(f'Could not read object metadata: {metadata_error}')

        if detection_mode not in ('labels', 'celebrity'):
            if object_key.startswith('uploads/celebrity/'):
                detection_mode = 'celebrity'
            else:
                detection_mode = 'labels'

        image = {
            'S3Object': {
                'Bucket': bucket_name,
                'Name': object_key,
            }
        }

        try:
            if detection_mode == 'celebrity':
                result = rekognition.recognize_celebrities(Image=image)
                print('Rekognition celebrity result:', json.dumps(result, indent=2, default=str))

                result_data = {
                    'originalImage': object_key,
                    'timestamp': datetime.utcnow().isoformat(),
                    'detectionMode': detection_mode,
                    'celebrities': result.get('CelebrityFaces', []),
                    'unrecognizedFaces': result.get('UnrecognizedFaces', []),
                    'responseMetadata': result.get('ResponseMetadata', {})
                }
            else:
                result = rekognition.detect_labels(Image=image, MaxLabels=10, MinConfidence=75)
                print('Rekognition label result:', json.dumps(result, indent=2, default=str))

                result_data = {
                    'originalImage': object_key,
                    'timestamp': datetime.utcnow().isoformat(),
                    'detectionMode': detection_mode,
                    'labels': result.get('Labels', []),
                    'responseMetadata': result.get('ResponseMetadata', {})
                }

            result_key = f"results/{object_key.replace('/', '-')}.json"
            print(f'Storing results to s3://{bucket_name}/{result_key}')
            s3.put_object(
                Bucket=bucket_name,
                Key=result_key,
                Body=json.dumps(result_data, indent=2, default=str),
                ContentType='application/json'
            )
            print(f'Stored Rekognition results to s3://{bucket_name}/{result_key}')

        except Exception as error:
            print(f'Rekognition failed: {error}')
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
                print(f'Stored error log to s3://{bucket_name}/{error_key}')
            except Exception as s3_error:
                print(f'Failed to store error log: {s3_error}')

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Processed SQS batch.'})
    }
