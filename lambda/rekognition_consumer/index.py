import json
from pathlib import Path
import boto3
import base64
import urllib.parse
import os
from datetime import datetime
import random
from monitoring import (
    track_image_processed,
    track_error,
    track_image_size,
    RekognitionTimer,
)

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')
sqs = boto3.client('sqs')
bucket = os.environ['IMAGE_BUCKET_NAME']
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['VIDEO_JOB_TABLE'])


def handler(event, context):
    print(f"Received event: {os.environ['SNSTopicArn']}")
    print(f"Received event: {os.environ['IAM_ROLE_ARN']}")

    detection_mode = "unknown"

    try:
        for record in event.get('Records', []):
            body = json.loads(record['body'])

        if 'Records' in body:
            for s3_record in body['Records']:
                try:
                    object_key = urllib.parse.unquote_plus(s3_record['s3']['object']['key'])
                    bucket_name = s3_record['s3']['bucket']['name']
                    object_size = s3_record['s3']['object'].get('size', 0)

                    image = {
                        'S3Object': {
                            'Bucket': bucket,
                            'Name': object_key
                        }
                    }

                    file_type = Path(object_key).suffix
                    if file_type not in ['.jpg', '.jpeg', '.png', '.mp4', '.mov']:
                        print(f"Archivo {object_key} no es un archivo válido.")
                        return {
                            'statusCode': 400,
                            'body': json.dumps({'message': 'Archivo no es un archivo válido.'})
                        }

                    try:
                        metadata = s3.head_object(Bucket=bucket_name, Key=object_key)
                    except Exception as s3_err:
                        print(f"S3 head_object error: {s3_err}")
                        track_error(component="s3", function_name=context.function_name)
                        raise

                    metadatos = metadata.get('Metadata', {})
                    detection_mode = metadatos.get('detection_mode', 'unknown')
                    print(f"Metadata for object {object_key}: {metadata.get('Metadata')}")
                    print(f"Detected file_type={file_type} and detection_mode={detection_mode}")

                    # Record size of the object being processed
                    track_image_size(object_size, file_type=file_type)

                    formatted = {
                        "mode": detection_mode,
                        "items": []
                    }

                    try:
                        response_image = s3.get_object(Bucket=bucket_name, Key=object_key)
                        image_bytes = response_image['Body'].read()
                    except Exception as s3_err:
                        print(f"S3 get_object error: {s3_err}")
                        track_error(component="s3", function_name=context.function_name)
                        raise

                    if file_type in ['.jpg', '.jpeg', '.png']:
                        # --- Moderation check ---
                        try:
                            with RekognitionTimer("moderation"):
                                moderation_content = rekognition.detect_moderation_labels(
                                    Image=image, MinConfidence=75
                                )
                        except Exception as rek_err:
                            print(f"Rekognition moderation error: {rek_err}")
                            track_error(component="rekognition", function_name=context.function_name)
                            raise

                        for item in moderation_content['ModerationLabels']:
                            print(f"Moderation label: {item}")
                            if item['Name'] in ('Explicit Sexual Activity', 'Exposed Female Genitalia'):
                                print("Imagen no permitida")
                                mensaje = json.dumps({
                                    "mensaje_servidor": "explicit",
                                    "info": "The image contains inappropiate content"
                                })
                                try:
                                    gatewayapi = boto3.client(
                                        "apigatewaymanagementapi",
                                        endpoint_url=metadatos.get('domainname')
                                    )
                                    gatewayapi.post_to_connection(
                                        ConnectionId=metadatos.get('connection_id'),
                                        Data=mensaje
                                    )
                                except Exception as apigw_err:
                                    print(f"API Gateway error (moderation block): {apigw_err}")
                                    track_error(component="apigateway", function_name=context.function_name)
                                track_image_processed(
                                    status="blocked",
                                    detection_mode="moderation",
                                    function_name=context.function_name
                                )
                                return

                        # Bounding boxes for Pillow
                        boxes_to_draw = []

                        # --- Detection ---
                        try:
                            if detection_mode == 'labels':
                                with RekognitionTimer("labels"):
                                    result = rekognition.detect_labels(
                                        Image=image, MaxLabels=20, MinConfidence=60
                                    )
                                for item in result.get('Labels', []):
                                    formatted["items"].append({
                                        "name": item['Name'],
                                        "confidence": round(item['Confidence'], 2)
                                    })
                                    for instance in item.get('Instances', []):
                                        if 'BoundingBox' in instance:
                                            boxes_to_draw.append(instance['BoundingBox'])

                            elif detection_mode == 'celebrity':
                                with RekognitionTimer("celebrity"):
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
                                with RekognitionTimer("text"):
                                    result = rekognition.detect_text(Image=image)
                                for text in result.get('TextDetections', []):
                                    if text['Type'] == 'LINE':
                                        formatted["items"].append({
                                            'Text': text['DetectedText'],
                                            'Confidence': round(text['Confidence'], 2),
                                            'Id': text['Id']
                                        })

                        except Exception as rek_err:
                            print(f"Rekognition detection error: {rek_err}")
                            track_error(component="rekognition", function_name=context.function_name)
                            raise

                        # --- Pillow bounding boxes ---
                        if detection_mode == 'labels' and boxes_to_draw:
                            try:
                                import io
                                from PIL import Image as PILImage, ImageDraw

                                img = PILImage.open(io.BytesIO(image_bytes))
                                img_w, img_h = img.size
                                draw = ImageDraw.Draw(img)

                                for box in boxes_to_draw:
                                    left   = img_w * box['Left']
                                    top    = img_h * box['Top']
                                    width  = img_w * box['Width']
                                    height = img_h * box['Height']
                                    shape  = [left, top, left + width, top + height]
                                    random_color = (
                                        random.randint(0, 255),
                                        random.randint(0, 255),
                                        random.randint(0, 255),
                                    )
                                    draw.rectangle(shape, outline=random_color, width=4)

                                output_buffer = io.BytesIO()
                                img_format = img.format if img.format else (
                                    'PNG' if file_type == '.png' else 'JPEG'
                                )
                                img.save(output_buffer, format=img_format)
                                image_bytes = output_buffer.getvalue()
                                print(f"Imagen procesada con Pillow exitosamente. Nuevos bytes: {len(image_bytes)}")

                            except Exception as pillow_error:
                                print(f"Error procesando la imagen con Pillow: {pillow_error}")
                                track_error(component="pillow", function_name=context.function_name)

                        # --- Send result to API Gateway ---
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

                        try:
                            gatewayapi = boto3.client(
                                "apigatewaymanagementapi",
                                endpoint_url=metadatos.get('domainname')
                            )
                            response_gateway = gatewayapi.post_to_connection(
                                ConnectionId=metadatos.get('connection_id'),
                                Data=json.dumps(payload)
                            )
                            print(f"Resultado del post_to_connection: {response_gateway}")
                        except Exception as apigw_err:
                            print(f"API Gateway post_to_connection error: {apigw_err}")
                            track_error(component="apigateway", function_name=context.function_name)
                            raise

                    elif file_type in ['.mp4', '.mov']:
                        print(f"Video branch reached. detection_mode={metadatos.get('detection_mode')}")
                        if metadatos.get('detection_mode') == 'videos':
                            print("Starting Rekognition label detection for video")
                            try:
                                with RekognitionTimer("videos"):
                                    result = rekognition.start_label_detection(
                                        Video={
                                            'S3Object': {
                                                'Bucket': bucket,
                                                'Name': object_key
                                            }
                                        },
                                        NotificationChannel={
                                            'SNSTopicArn': os.environ['SNSTopicArn'],
                                            'RoleArn': os.environ['IAM_ROLE_ARN']
                                        },
                                        MinConfidence=85.0
                                    )
                            except Exception as rek_err:
                                print(f"Rekognition start_label_detection error: {rek_err}")
                                track_error(component="rekognition", function_name=context.function_name)
                                raise

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

                            track_image_processed(
                                status="success",
                                detection_mode="videos",
                                function_name=context.function_name
                            )
                            return {
                                'statusCode': 200,
                                'jobId': result['JobId']
                            }
                        else:
                            print("Video file was uploaded but detection_mode is not 'videos'.")

                except KeyError as e:
                    print(f"Error: No se encontró la clave {e} en el evento de S3")
                    track_error(component="other", function_name=context.function_name)

    except Exception as metadata_error:
        print(f'Could not read object metadata: {metadata_error}')
        track_image_processed(
            status="error",
            detection_mode=detection_mode,
            function_name=context.function_name
        )
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error processing SQS batch.'})
        }

    track_image_processed(
        status="success",
        detection_mode=detection_mode,
        function_name=context.function_name
    )
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Processed SQS batch.'})
    }
