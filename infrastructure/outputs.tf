output "api_url" {
  description = "HTTP API endpoint for requesting presigned upload URLs."
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "image_bucket_name" {
  description = "Name of the image S3 bucket."
  value       = aws_s3_bucket.image_bucket.bucket
}

output "sqs_queue_url" {
  description = "URL of the SQS queue receiving image upload notifications."
  value       = aws_sqs_queue.image_notifications.id
}

output "rekognition_lambda_name" {
  description = "Name of the Rekognition consumer Lambda function."
  value       = aws_lambda_function.rekognition_consumer.function_name
}

output "presigned_url_lambda_name" {
  description = "Name of the Lambda function that issues presigned URLs."
  value       = aws_lambda_function.presigned_url.function_name
}

output "websocket" {
  description = "websocket"
  value = aws_apigatewayv2_api.websocket.api_endpoint
}

output "websocket_url" {
  description = "wss endpoint"
  value = replace(aws_apigatewayv2_stage.websocket_stage.invoke_url, "wss://", "https://")
}
