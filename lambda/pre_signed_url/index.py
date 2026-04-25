import os
import json
import boto3
import time
import uuid
from botocore.exceptions import ClientError
sqs = boto3.client('sqs')
QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/688567305851/rekognition-image-queue"

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('mapping-routes')
connection_table = dynamodb.Table('websocket-connections')


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
    print(f"Determined detection mode: {detection_mode}")
    print(f"Rawpath: {event.get('rawPath')}")
    
    raw_path = event.get('rawPath') or event.get('requestContext', {}).get('http', {}).get('path', '')
    if raw_path.endswith('/celebrity'):
        detection_mode = 'celebrity'
    elif raw_path.endswith('/labels'):
        detection_mode = 'labels'

    if detection_mode not in ('labels', 'celebrity'):
        detection_mode = 'labels'

    content_type = payload.get('contentType') 
    filename = payload.get('filename')
    websocket_connection_id = payload.get('WebSocketConnectionId')
    bucket = os.environ.get('S3_BUCKET_NAME')

    if not bucket:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Missing S3_BUCKET_NAME environment variable.'})
        }

    lastpart = f"{uuid.uuid4()}-{filename}"
    if filename:
        key_name = f"{prefix}{detection_mode}/{lastpart}"
    else:
        key_name = f"{prefix}{detection_mode}/{uuid.uuid4()}"

    metadata = {
        'detection_mode': detection_mode,
        "connection_id": payload.get('WebSocketConnectionId'),
        "domainName": "https://wh08cwowvj.execute-api.us-east-1.amazonaws.com/$default/",
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

        # sqs.send_message(
        #     QueueUrl=QUEUE_URL,
        #     MessageBody=json.dumps({
                
        #         })
        #     )
        # item_id = lastpart
        print(f"Este es el key name generado: {key_name}")
        # table.put_item(
        # Item={
        #     'id': item_id,         # Esta es tu Partition Key
        #     's3_uri': f"s3://rekognition-image-bucket123456/uploads/{detection_mode}/{item_id}",      # s3://rekognition-image...
        #     's3_url': f"https://rekognition-image-bucket123456.s3.us-east-1.amazonaws.com/uploads/{detection_mode}/{item_id}",    
        #     'timestamp': '2023-10-27T10:00:00Z' # Opcional: para saber cuándo se subió
        #     }
        # )

        connection_table.put_item(
        Item={
            'id': websocket_connection_id,         # Esta es tu Partition Key
            'timestamp': '2023-10-27T10:00:00Z' # Opcional: para saber cuándo se subió
            }
        )
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
