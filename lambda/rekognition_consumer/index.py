import json
from pathlib import Path
import boto3
import base64
import os
from datetime import datetime
import random  # Requerido para colores aleatorios
import io      # Requerido para manejar bytes de imágenes en memoria

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
                    detection_mode = metadatos.get('detection_mode')
                    print(f"Metadata for object {object_key}: {metadata.get('Metadata')}")
                    print(f"Detected file_type={file_type} and detection_mode={detection_mode}")
                    
                    formatted = {
                        "mode": detection_mode,
                        "items": []
                    }
                    response_image = s3.get_object(Bucket=bucket_name, Key=object_key)
                    image_bytes = response_image['Body'].read()
                    
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
                        
                        # Lista para guardar las cajas de coordenadas que Pillow va a dibujar
                        boxes_to_draw = []

                        if detection_mode == 'labels':
                            result = rekognition.detect_labels(Image=image, MaxLabels=20, MinConfidence=60)
                            for item in result.get('Labels', []):
                                formatted["items"].append({
                                    "name": item['Name'],
                                    "confidence": round(item['Confidence'], 2)
                                })
                                for instance in item.get('Instances', []):
                                    if 'BoundingBox' in instance:
                                        boxes_to_draw.append(instance['BoundingBox'])
                                                     
                        elif detection_mode == 'celebrity':
                            result = rekognition.recognize_celebrities(Image=image)
                            for item in result.get('CelebrityFaces', []):
                                formatted["items"].append({
                                    "name": item['Name'],
                                    "confidence": round(item['MatchConfidence'], 2),
                                    "urls": item.get('Urls', [])
                                })
                                if 'Face' in item and 'BoundingBox' in item['Face']:
                                    boxes_to_draw.append(item['Face']['BoundingBox'])

                        elif detection_mode == 'text':
                            result = rekognition.detect_text(Image=image)
                            text_detections = result.get('TextDetections', [])
                            for text in text_detections:
                                if text['Type'] == 'LINE':
                                    formatted["items"].append({
                                        'Text': text['DetectedText'],
                                        'Confidence': round(text['Confidence'], 2),
                                        'Id': text['Id']
                                    })

                        # --- PROCESAMIENTO CON PILLOW ---
                        if detection_mode in ['labels'] and boxes_to_draw:
                            try:
                                from PIL import Image as PILImage, ImageDraw
                                
                                img = PILImage.open(io.BytesIO(image_bytes))
                                img_w, img_h = img.size
                                draw = ImageDraw.Draw(img)

                                for box in boxes_to_draw:
                                    left = img_w * box['Left']
                                    top = img_h * box['Top']
                                    width = img_w * box['Width']
                                    height = img_h * box['Height']
                                    
                                    shape = [left, top, left + width, top + height]
                                    random_color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
                                    draw.rectangle(shape, outline=random_color, width=4)

                                output_buffer = io.BytesIO()
                                # Forzamos formato PNG/JPEG compatible si viene vacío
                                img_format = img.format if img.format else ('PNG' if file_type == '.png' else 'JPEG')
                                img.save(output_buffer, format=img_format)
                                image_bytes = output_buffer.getvalue()
                                print(f"Imagen procesada con Pillow exitosamente. Nuevos bytes: {len(image_bytes)}")
                                
                            except Exception as pillow_error:
                                print(f"Error procesando la imagen con Pillow: {pillow_error}")

                        # --- CONSTRUCCIÓN DEL PAYLOAD FINAL (OBLIGATORIO AQUÍ) ---
                        encoded_image = base64.b64encode(image_bytes).decode('utf-8')
                        
                        payload = {
                            "filename": object_key,
                            "type": file_type,
                            "data": encoded_image,
                            "mensaje_servidor": "resultados",
                            "info": formatted
                        }

                        print(f"Enviando respuesta a API Gateway. ConnectionId: {metadatos.get('connection_id')}")
                        print(f"Endpoint URL usado: {metadatos.get('domainname')}")
                        
                        gatewayapi = boto3.client(
                            "apigatewaymanagementapi", 
                            endpoint_url=metadatos.get('domainname')
                        )

                        # Cambiamos el json.dumps directo aquí para asegurar consistencia
                        response_gateway = gatewayapi.post_to_connection(
                            ConnectionId=metadatos.get('connection_id'),
                            Data=json.dumps(payload)  
                        )
                        print(f"Resultado del post_to_connection: {response_gateway}")
                        
                        #s3.delete_object(Bucket=bucket_name, Key=object_key)
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
                                },MinConfidence=85.0)
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
