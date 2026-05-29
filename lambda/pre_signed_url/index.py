import os
import json
import boto3
import time
import uuid

domain_name = os.environ.get('API_DOMAIN_NAME')
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def handler(event, context):
    payload = {}
    body = event.get('body')
    print(f"Received event: {json.dumps(event)}")
    if body:
        try:
            payload = json.loads(body)
        except Exception:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid JSON body.'})
            }
        
    prefix = os.environ.get('UPLOAD_PREFIX')
    detection_mode = ''

    print("payload dumping: ", json.dumps(payload))
    print(f"Received event: {json.dumps(event)}")
    print(f"path: {event.get('path')}")
    print(f"Rawpath: {event.get('rawPath')}")
    
    raw_path = event.get('path') or event.get('rawPath') or event.get('requestContext', {}).get('http', {}).get('path', '')
    if raw_path.endswith('/celebrity'):
        detection_mode = 'celebrity'
    elif raw_path.endswith('/labels'):
        detection_mode = 'labels'
    elif raw_path.endswith('/videos'):
        detection_mode = 'videos'
    elif raw_path.endswith('/text'):
        detection_mode = 'text'
    if detection_mode not in ('labels', 'celebrity', 'videos', 'text'):
        detection_mode = 'labels'

    content_type = payload.get('contentType') 
    filename = payload.get('filename')
    bucket = os.environ.get('S3_BUCKET_NAME')

    if not bucket:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Missing S3_BUCKET_NAME environment variable.'})
        }

    lastpart = f"{uuid.uuid4()}-{filename}"
    if filename:
        key_name = f"{prefix}{detection_mode}/{lastpart}"

    metadata = {
        'detection_mode': detection_mode,
        "connection_id": payload.get('WebSocketConnectionId'),
        "domainName": domain_name,
        "stage": "default",
        "image_id": lastpart
    }

    try:
        upload_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket,
                'Key': key_name,
                'ContentType': content_type,
                'Metadata': metadata
            },
            ExpiresIn=300
        )

        print(f"Este es el key name generado: {key_name}")

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Failed to generate presigned URL: {str(e)}'})
        }


    # upload presigned URL for image upload
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
         },
        'body': json.dumps({
            'uploadUrl': upload_url,
            'key': key_name,
            'bucket': bucket,
            'expiresInSeconds': 300,
            'detection_mode': detection_mode,
            'stage': "default",
            'imageId': lastpart
        })
    }
