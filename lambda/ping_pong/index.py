import json
import boto3

def handler(event, context):
    # 1. AWS te da automáticamente el ID de conexión del celular que envió el ping
    connection_id = event['requestContext']['connectionId']
   
    # 2. Construir la URL de administración (callbackUrl) dinámicamente
    domain_name = event['requestContext']['domainName']
    stage = event['requestContext']['stage']
    callback_url = f"https://{domain_name}/{stage}"
   
    # 3. Inicializar el cliente de API Gateway Management API
    apigw_client = boto3.client('apigatewaymanagementapi', endpoint_url=callback_url)
   
    try:
        # 4. Enviar el mensaje 'pong' de vuelta al celular
        response_data = json.dumps({"ping": "pong"})
        apigw_client.post_to_connection(
            ConnectionId=connection_id,
            Data=response_data
        )
       
        return {
            'statusCode': 200,
            'body': json.dumps('Pong enviado exitosamente.')
        }
       
    except Exception as e:
        print(f"Error enviando el pong al connectionId {connection_id}: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error en el heartbeat.')
        }