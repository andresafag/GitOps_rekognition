import os
import json
import boto3
import time
import uuid

s3 = boto3.client('s3')


def handler(event, context):
    query_params = event.get('queryStringParameters') or {}
    prefix = os.environ.get('UPLOAD_PREFIX', 'uploads/')
    key = query_params.get('key') or f"{prefix}{int(time.time() * 1000)}-{uuid.uuid4().hex[:8]}"
    content_type = query_params.get('contentType', 'image/jpeg')
    bucket = os.environ.get('S3_BUCKET_NAME')

    if not bucket:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Missing S3_BUCKET_NAME environment variable.'})
        }

    try:
        upload_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket,
                'Key': key,
                'ContentType': content_type,
            },
            ExpiresIn=900
        )
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Failed to generate presigned URL: {str(e)}'})
        }

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'uploadUrl': upload_url,
            'key': key,
            'bucket': bucket,
            'expiresInSeconds': 900,
        })
    }
