import os
import json
import boto3
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients outside the handler for connection reuse
rekognition_client = boto3.client('rekognition')
s3_client = boto3.client('s3')
s3 = boto3.client('s3')
# bucket = os.environ['IMAGE_BUCKET_NAME']

def handler(event, context):
    try:
        for record in event.get('Records', []):
            body = json.loads(record['body'])
        if 'Records' in body:
            for s3_record in body['Records']:
                try:
                    object_key = s3_record['s3']['object']['key']
                    bucket_name = s3_record['s3']['bucket']['name']
        
                    logger.info(f"Processing file from Bucket: {bucket_name}, Key: {object_key}")

                    # 2. Call Amazon Rekognition DetectText API
                    response = rekognition_client.detect_text(
                        Image={
                            'S3Object': {
                                'Bucket': bucket_name,
                                'Name': object_key
                            }
                        }
                    )

                    # 3. Extract text detections
                    text_detections = response.get('TextDetections', [])
                    extracted_results = []

                    for text in text_detections:
                        # Type can be 'LINE' or 'WORD'
                        if text['Type'] == 'LINE':
                            extracted_results.append({
                                'Text': text['DetectedText'],
                                'Confidence': round(text['Confidence'], 2),
                                'Id': text['Id']
                            })

                    logger.info(f"Successfully detected {len(extracted_results)} lines of text.")

                    # 4. Return successful response
                    return {
                        'statusCode': 200,
                        'body': json.dumps({
                            'message': 'Text detection complete',
                            'detected_text': extracted_results
                        })
                    }
                except KeyError as e:
                    print(f"Error: No se encontró la clave {e} en el evento de S3")
        
    except Exception as e:
        logger.error(f"Error processing text: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error processing text'})
        }
