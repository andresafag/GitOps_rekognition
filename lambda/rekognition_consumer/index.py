import json
from pathlib import Path
import boto3
import base64
import os
from datetime import datetime

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')
sqs = boto3.client('sqs')
bucket = os.environ['IMAGE_BUCKET_NAME']
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['VIDEO_JOB_TABLE'])


def handler(event, context):
    print(f"Received event: {os.environ['SNSTopicArn']}")
    print(f"Received event: {os.environ['IAM_ROLE_ARN']}")
    try:
        for record in event.get('Records', []):
            body = json.loads(record['body'])
        if 'Records' in body:
            for s3_record in body['Records']:
                try:
                    object_key = s3_record['s3']['object']['key']
                    bucket_name = s3_record['s3']['bucket']['name']

                    image = {
                        'S3Object': {
                        'Bucket': bucket,
                        'Name': object_key
                        }
                    }
                    file_type = Path(object_key).suffix
                    if file_type not in ['.jpg', '.jpeg', '.png','.mp4','.mov']:
                        print(f"Archivo {object_key} no es un archivo válido.")
                        return {
                            'statusCode': 400,
                            'body': json.dumps({'message': 'Archivo no es un archivo válido.'})
                        }

                    metadata = s3.head_object(Bucket=bucket_name, Key=object_key)
                    metadatos = metadata.get('Metadata', {})
                    print(f"Metadata for object {object_key}: {metadata.get('Metadata')}")
                    print(f"Detected file_type={file_type} and detection_mode={metadatos.get('detection_mode')}")
                    formatted = {
                        "mode": metadatos.get('detection_mode'),
                        "items": []
                    }
                    response_image = s3.get_object(Bucket=bucket_name, Key=object_key)
                    image_bytes = response_image['Body'].read()
                    encoded_image = base64.b64encode(image_bytes).decode('utf-8')
                    payload = {
                        "filename": object_key,
                        "type": file_type,
                        "data": encoded_image,
                        "mensaje_servidor": "resultados",
                        "info": formatted
                    }
                    if file_type in ['.jpg', '.jpeg', '.png']:
                        moderation_content = rekognition.detect_moderation_labels(Image=image, MinConfidence=75)
                        for item in moderation_content['ModerationLabels']:
                            print(f"Moderation label: {item}")
                            if item['Name'] == 'Explicit Sexual Activity' or item['Name'] == 'Exposed Female Genitalia':
                                print("Imagen no permitida")
                                mensaje=json.dumps({
                                    "mensaje_servidor": "explicit",
                                    "info": "The image contains inappropiate content"
                                })
                                gatewayapi = boto3.client(
                                    "apigatewaymanagementapi",
                                    endpoint_url=metadatos.get('domainname')
                                )
                                gatewayapi.post_to_connection(
                                    ConnectionId=metadatos.get('connection_id'),
                                    Data=mensaje
                                )
                                return
                        if metadatos.get('detection_mode') == 'labels':
                            result = rekognition.detect_labels(Image=image, MaxLabels=10, MinConfidence=75)
                            for item in result.get('Labels', []):
                                formatted["items"].append({
                                    "name": item['Name'],
                                    "confidence": round(item['Confidence'], 2)
                                })                        
                        elif metadatos.get('detection_mode') == 'celebrity':
                            result = rekognition.recognize_celebrities(Image=image)
                            for item in result.get('CelebrityFaces', []):
                                formatted["items"].append({
                                    "name": item['Name'],
                                    "confidence": round(item['MatchConfidence'], 2),
                                    "urls": item.get('Urls', [])
                                })

                        print(formatted)
                        gatewayapi = boto3.client(
                        "apigatewaymanagementapi", 
                        endpoint_url=metadatos.get('domainname')
                        )

                        gatewayapi.post_to_connection(
                            ConnectionId=metadatos.get('connection_id'),
                            Data=json.dumps(payload)  
                        )
                        s3.delete_object(Bucket=bucket_name, Key=object_key)
                    elif file_type in ['.mp4', '.mov']:
                        print(f"Video branch reached. detection_mode={metadatos.get('detection_mode')}")
                        if metadatos.get('detection_mode') == 'videos':
                            print("Starting Rekognition label detection for video")
                            result = rekognition.start_label_detection(Video={
                                'S3Object': 
                                    {'Bucket': bucket,
                                     'Name': object_key}
                                },
                                NotificationChannel={
                                    'SNSTopicArn': os.environ['SNSTopicArn'],
                                    'RoleArn': os.environ['IAM_ROLE_ARN']
                                })
                            table.put_item(Item={
                                'JobId': result['JobId'],
                                'connection_id': metadatos.get('connection_id'),
                                'domainname': metadatos.get('domainname'),
                                'bucket': bucket_name,
                                'key': object_key,
                                'detection_mode': metadatos.get('detection_mode'),
                                'created_at': datetime.utcnow().isoformat()
                            })

                            print(f"start_label_detection response: {result}")
                            return {
                                'statusCode': 200,
                                'jobId': result['JobId']
                            }
                        else:
                            print("Video file was uploaded but detection_mode is not 'videos'.")
    
                except KeyError as e:
                    print(f"Error: No se encontró la clave {e} en el evento de S3")

    except Exception as metadata_error:
        print(f'Could not read object metadata: {metadata_error}')


    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Processed SQS batch.'})
    }
