output "website_url" {
  description = "Website URL"
  value       = "https://rekoglabelify.com"
}

output "aws_lambda_function_presigned_url_arn" {
  description = "ARN of the Lambda function that issues presigned URLs."
  value       = module.lambda.aws_lambda_function_presigned_url_arn
}

output "api_gateway_http_execution_arn" {
  description = "ARN of the API Gateway HTTP execution"
  value       = module.apigateway.api_gateway_http_execution_arn
}

output "api_gateway_websocket_execution_arn" {
  description = "ARN of the API Gateway WebSocket execution"
  value       = module.apigateway.api_gateway_websocket_execution_arn
}

output "image_bucket_name" {
  description = "Name of the S3 bucket that stores uploaded images."
  value       = module.s3.image_bucket_name
}

output "api_domain_name" {
  description = "Custom domain name for the API Gateway."
  value       = module.apigateway.api_domain_name
}

output "role_presigned_url" {
  description = "ARN of the IAM role for the presigned URL Lambda function."
  value       = module.iam.role_presigned_url
}

output "role_ping_pong" {
  value = module.iam.role_ping_pong
}

output "aws_lambda_function_ping_pong_arn" {
  value = module.lambda.aws_lambda_function_ping_pong_arn
}

output "role_rekognition_consumer" {
  description = "ARN of the IAM role for the Rekognition consumer Lambda function."
  value       = module.iam.role_rekognition_consumer
}


output "websocket_stage_invokeurl" {
  value = module.apigateway.websocket_stage_invokeurl
}

output "aws_sqs_queue_policy" {
  value = module.iam.aws_sqs_queue_policy
}


output "website_bucket_name" {
  description = "Name of the S3 bucket that hosts the static website."
  value       = module.s3.website_bucket_name
}

output "aws_cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution."
  value       = module.cloudfront.aws_cloudfront_distribution_domain_name
}

output "aws_cloudfront_distribution_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution."
  value       = module.cloudfront.aws_cloudfront_distribution_hosted_zone_id
}

output "data_aws_s3_bucket_website_id_bucket_regional_domain_name" {
  description = "ID of the S3 bucket that hosts the static website."
  value       = module.s3.data_aws_s3_bucket_website_id_bucket_regional_domain_name
}

output "aws_acm_certificate_validation_certificate_arn" {
  description = "ACM certificate validation for the CloudFront distribution."
  value       = module.route_53.aws_acm_certificate_validation_certificate_arn
}

output "sqs_queue_name" {
  description = "Name of the SQS queue receiving image upload notifications."
  value       = module.sns.sqs_queue_name
}

output "aws_sqs_queue_image_notifications_name" {
    description = "Name of the SQS queue receiving image upload notifications."
    value       = module.sns.aws_sqs_queue_image_notifications_name
}

output "aws_sns_topic_dlq_alert_arn" {
    description = "ARN of the SNS topic for dead-letter queue alerts."
    value       = module.sns.aws_sns_topic_dlq_alert_arn
}

output "aws_sqs_queue_dead_letter_queue_name" {
  description = "Name of the SQS dead-letter queue for failed messages."
  value = module.sns.aws_sqs_queue_dead_letter_queue_name
}

output "data_aws_s3_bucket_website_id" {
  description = "ID of the S3 bucket that hosts the static website."
  value       = module.s3.data_aws_s3_bucket_website_id
}

output "aws_cloudfront_origin_access_identity_iam_arn" {
  description = "IAM ARN of the CloudFront origin access identity."
  value       = module.cloudfront.aws_cloudfront_origin_access_identity_iam_arn
}

output "data_aws_s3_bucket_website_arn" {
  description = "ARN of the S3 bucket that hosts the static website."
  value = module.s3.data_aws_s3_bucket_website_arn
}

output "aws_s3_bucket_image_bucket_arn" {
  description = "ARN of the S3 bucket that stores uploaded images."
  value = module.s3.aws_s3_bucket_image_bucket_arn
}

output "aws_acm_certificate_website_arn" {
  description = "ARN of the ACM certificate for the CloudFront distribution."
  value       = module.cloudfront.certificate_arn
}


output "aws_acm_certificate_website" {
  description = "ACM Certificate for the CloudFront distribution."
  value       = module.cloudfront.aws_acm_certificate_website
}


output "aws_cloudwatch_log_group_api_gateway_logs_arn" {
    description = "ARN of the CloudWatch Log Group for API Gateway access logs."
    value       = module.cloudwatch.aws_cloudwatch_log_group_api_gateway_logs_arn
}

output "aws_iam_role_apigw_log_role_arn" {
  value = module.iam.aws_iam_role_apigw_log_role_arn
}

output "aws_sqs_queue_image_notifications_id" {
  value = module.sns.aws_sqs_queue_image_notifications_id
}

output "aws_sqs_queue_image_notifications_arn" {
    description = "ARN of the SQS queue receiving image upload notifications."
    value       = module.sns.aws_sqs_queue_image_notifications_arn
}

output "aws_apigatewayv2_api_http_api_api_endpoint" {
  value = module.apigateway.aws_apigatewayv2_api_http_api_api_endpoint
}

output "aws_apigatewayv2_api_websocket_api_endpoint" {
  value = module.apigateway.aws_apigatewayv2_api_websocket_api_endpoint
}

output "aws_sns_topic_rekognition_video_updates_arn" {
  value = module.sns.aws_sns_topic_rekognition_video_updates_arn
}


output "aws_iam_role_rekognition_service_role" {
  value = module.iam.aws_iam_role_rekognition_service_role
}

output "aws_iam_role_video_proccessing_lambda_role" {
  value = module.iam.aws_iam_role_video_proccessing_lambda_role
}

output "aws_lambda_function_video_proccessing_arn" {
  value = module.lambda.aws_lambda_function_video_proccessing_arn
}


output "aws_sqs_queue_rekognition_video_updates" {
  description = "ARN of the SQS queue for rekognition video updates."
  value       = module.sns.aws_sqs_queue_rekognition_video_updates
}


output "aws_sqs_queue_policy_allow_sns_send_message_queue_url" {
  description = "URL of the SQS queue policy that allows SNS to send messages."
  value       = module.sns.aws_sqs_queue_policy_allow_sns_send_message_queue_url
}

output "aws_dynamodb_table_video_job_table_name" {
  value = module.dynamodb.aws_dynamodb_table_video_job_table_name 
}

output "aws_dynamodb_table_video_job_table_arn" {
  value = module.dynamodb.aws_dynamodb_table_video_job_table_arn
}

