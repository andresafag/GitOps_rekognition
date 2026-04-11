import os
import json
import boto3
import time
import uuid
from botocore.exceptions import ClientError

s3 = boto3.client('s3')


def handler(event, context):
    payload = {}
    body = event.get('body')
    if body:
        try:
            payload = json.loads(body)
        except Exception:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid JSON body.'})
            }

    query_params = event.get('queryStringParameters') or {}
    prefix = os.environ.get('UPLOAD_PREFIX', 'uploads/')
    detection_mode = payload.get('detectionMode') or payload.get('mode') or query_params.get('detectionMode') or 'labels'
    detection_mode = detection_mode.lower() if isinstance(detection_mode, str) else 'labels'

    raw_path = event.get('rawPath') or event.get('requestContext', {}).get('http', {}).get('path', '')
    if raw_path.endswith('/celebrity'):
        detection_mode = 'celebrity'
    elif raw_path.endswith('/labels'):
        detection_mode = 'labels'

    if detection_mode not in ('labels', 'celebrity'):
        detection_mode = 'labels'

    content_type = payload.get('contentType') or query_params.get('contentType') or 'image/jpeg'
    filename = payload.get('filename') or query_params.get('filename')
    bucket = os.environ.get('S3_BUCKET_NAME')

    if not bucket:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Missing S3_BUCKET_NAME environment variable.'})
        }

    if raw_path.endswith('/results') and event.get('requestContext', {}).get('http', {}).get('method', '') == 'GET':
        query_params = event.get('queryStringParameters') or {}
        result_key = query_params.get('key')
        if not result_key:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Missing result key.'})
            }

        try:
            result_object = s3.get_object(Bucket=bucket, Key=result_key)
            body = result_object['Body'].read().decode('utf-8')
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': body
            }
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'NoSuchKey':
                return {
                    'statusCode': 404,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'error': 'Result not ready.'})
                }
            print(f'ClientError reading result object: {e}')
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': f'Failed to read result: {str(e)}'})
            }
        except Exception as e:
            print(f'Error reading result object: {str(e)}')
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': f'Failed to read result: {str(e)}'})
            }

    if filename:
        filename = os.path.basename(filename)
        key_name = f"{prefix}{detection_mode}/{int(time.time() * 1000)}-{uuid.uuid4().hex[:8]}-{filename}"
    else:
        key_name = f"{prefix}{detection_mode}/{int(time.time() * 1000)}-{uuid.uuid4().hex[:8]}"

    try:
        upload_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket,
                'Key': key_name,
                'ContentType': content_type,
                'Metadata': {
                    'detection-mode': detection_mode,
                },
            },
            ExpiresIn=300
        )
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Failed to generate presigned URL: {str(e)}'})
        }

    if raw_path.endswith('/results') and event.get('requestContext', {}).get('http', {}).get('method', '') == 'GET':
        query_params = event.get('queryStringParameters') or {}
        result_key = query_params.get('key')
        if not result_key:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Missing result key.'})
            }

        try:
            result_object = s3_bucket.get_object(Bucket=bucket, Key=result_key)
            body = result_object['Body'].read().decode('utf-8')
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': body
            }
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'NoSuchKey':
                return {
                    'statusCode': 404,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({'error': 'Result not ready.'})
                }
            print(f'ClientError reading result object: {e}')
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': f'Failed to read result: {str(e)}'})
            }
        except Exception as e:
            print(f'Error reading result object: {str(e)}')
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': f'Failed to read result: {str(e)}'})
            }

    # Generate result key and upload presigned URL for image upload
    result_key = f"results/{key_name.replace('/', '-')}.json"
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'uploadUrl': upload_url,
            'resultKey': result_key,
            'key': key_name,
            'bucket': bucket,
            'expiresInSeconds': 300,
            'detectionMode': detection_mode,
        })
    }
