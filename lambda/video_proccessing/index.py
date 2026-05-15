import json
import math
import uuid
import boto3
import os

rekognition = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['VIDEO_JOB_TABLE'])

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    for record in event['Records']:
        message_id = record['messageId']
        
        try:
            body = json.loads(record['body'])
            
            # Parse SNS message from SQS
            if 'Message' not in body:
                print(f"No 'Message' key in body for message {message_id}")
                continue
            
            sns_message = json.loads(body['Message'])
            job_id = sns_message.get('JobId')
            status = sns_message.get('Status')
            
            if not job_id:
                print(f"No JobId in SNS message for message {message_id}")
                continue
            
            print(f"Processing Job: {job_id} with status: {status}")
            
            # Retrieve job metadata from DynamoDB
            job_item = table.get_item(Key={'JobId': job_id}).get('Item')
            if not job_item:
                print(f"No job metadata found in DynamoDB for JobId: {job_id}")
                continue
            
            # Skip if already processed
            if job_item.get('processed'):
                print(f"Job {job_id} already processed, skipping.")
                continue
            
            connection_id = job_item.get('connection_id')
            domainname = job_item.get('domainname')
            
            if not connection_id or not domainname:
                print(f"Missing connection_id or domainname for JobId: {job_id}")
                continue
            
            print(f"Retrieved connection_id: {connection_id}, domainname: {domainname}")
            
            # Get all labels from Rekognition with pagination
            all_labels = []
            next_token = None
            
            while True:
                params = {'JobId': job_id}
                if next_token:
                    params['NextToken'] = next_token
                
                response = rekognition.get_label_detection(**params)
                labels = response.get('Labels', [])
                all_labels.extend(labels)
                
                next_token = response.get('NextToken')
                if not next_token:
                    break
            
            print(f"Total labels found: {len(all_labels)}")
            
            # Send results back to client via WebSocket
            gatewayapi = boto3.client('apigatewaymanagementapi', endpoint_url=domainname)
            results_payload = {
                "mensaje_servidor": "video_results",
                "labels": all_labels,
                "job_id": job_id
            }

            # Convertir el JSON completo a string y luego a bytes para medirlo
            payload_str = json.dumps(results_payload)
            payload_bytes = payload_str.encode('utf-8')
            
            TAMANO_BLOQUE = 110 * 1024 
            total_bytes = len(payload_bytes)
            total_fragmentos = math.ceil(total_bytes / TAMANO_BLOQUE)

            id_unique_msg = str(uuid.uuid4())
            for i in range(total_fragmentos):
                inicio = i * TAMANO_BLOQUE
                fin = inicio + TAMANO_BLOQUE
                fragmento_bytes = payload_bytes[inicio:fin]

                # Estructura de control para que el cliente sepa cómo reconstruir el mensaje
                mensaje_control = {
                    "id_mensaje": id_unique_msg,
                    "indice": i,
                    "total": total_fragmentos,
                    "datos": fragmento_bytes.decode('utf-8', errors='ignore')
                }

                # Enviar el fragmento individual a través del WebSocket
                try:
                    gatewayapi.post_to_connection(
                        ConnectionId=connection_id,
                        Data=json.dumps(
                            {"mensaje_servidor": "video_results_fragment",
                             **mensaje_control}
                        )
                    )
                except gatewayapi.exceptions.GoneException:
                    print(f"La conexión {connection_id} ya no existe.")
                    break
            
            # Mark job as processed
            table.update_item(
                Key={'JobId': job_id},
                UpdateExpression='SET #p = :val',
                ExpressionAttributeNames={'#p': 'processed'},
                ExpressionAttributeValues={':val': True}
            )
            print(f"Job {job_id} marked as processed")
        except Exception as e:
            print(f"Error procesando mensaje {message_id}: {str(e)}")
            raise e
    
    return {
        'statusCode': 200,
        'body': 'Mensajes procesados'
    }
