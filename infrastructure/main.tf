locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
  presigned_url_lambda_name = "rekognition-presigned-url-lambda"
  rekognition_lambda_name = "rekognition-consumer-lambda"
}



module "apigateway" {
  source   = "./modules/apigateway"
  integration_uri = module.lambda.aws_lambda_function_presigned_url_arn
  integration_uri_ping_route_arn = module.lambda.aws_lambda_function_ping_pong_arn
  aws_cloudwatch_log_group_api_gateway_logs_arn = module.cloudwatch.aws_cloudwatch_log_group_api_gateway_logs_arn
  aws_iam_role_apigw_log_role_arn = module.iam.aws_iam_role_apigw_log_role_arn
}

module "lambda" {
  source = "./modules/lambda"
  image_bucket_name = module.s3.image_bucket_name
  role_presigned_url_arn = module.iam.role_presigned_url
  role_rekognition_consumer_arn = module.iam.role_rekognition_consumer
  api_domain_name = module.apigateway.api_domain_name
  websocket_stage_invokeurl = module.apigateway.websocket_stage_invokeurl
  api_gateway_http_execution_arn = module.apigateway.api_gateway_http_execution_arn
  presigned_url_lambda_name = local.presigned_url_lambda_name
  rekognition_lambda_name = local.rekognition_lambda_name
  sqs_queue_image_notifications_arn = module.sns.aws_sqs_queue_image_notifications_arn
  aws_iam_role_rekognition_service_role = module.iam.aws_iam_role_rekognition_service_role
  aws_sns_topic_rekognition_video_updates_arn = module.sns.aws_sns_topic_rekognition_video_updates_arn
  role_video_proccessing_arn = module.iam.aws_iam_role_video_proccessing_lambda_role
  aws_sqs_queue_rekognition_video_updates_arn = module.sns.aws_sqs_queue_rekognition_video_updates
  aws_sqs_queue_policy_allow_sns_send_message_queue_url = module.sns.aws_sqs_queue_policy_allow_sns_send_message_queue_url
  aws_dynamodb_table_video_job_table_name = module.dynamodb.aws_dynamodb_table_video_job_table_name
  api_gateway_websocket_execution_arn = module.apigateway.api_gateway_websocket_execution_arn
  role_ping_pong = module.iam.role_ping_pong
}


module "s3" {
  source = "./modules/s3"
  allow_s3_send_message_policy = module.iam.aws_sqs_queue_policy
  sqs_queue_image_notifications_arn = module.sns.aws_sqs_queue_image_notifications_arn
  aws_apigatewayv2_api_http_api_api_endpoint = module.apigateway.aws_apigatewayv2_api_http_api_api_endpoint
  aws_apigatewayv2_api_websocket_api_endpoint = module.apigateway.aws_apigatewayv2_api_websocket_api_endpoint
  websocket_stage_invoke_url = module.apigateway.websocket_stage_invokeurl
}

module "iam" {
  source = "./modules/iam"
  data_aws_s3_bucket_website_id = module.s3.data_aws_s3_bucket_website_id
  aws_cloudfront_origin_access_identity_iam_arn = module.cloudfront.aws_cloudfront_origin_access_identity_iam_arn
  data_aws_s3_bucket_website_arn = module.s3.data_aws_s3_bucket_website_arn
  presigned_url_lambda_name = local.presigned_url_lambda_name
  rekognition_lambda_name = local.rekognition_lambda_name
  aws_s3_bucket_image_bucket_arn = module.s3.aws_s3_bucket_image_bucket_arn
  api_gateway_websocket_execution_arn = module.apigateway.api_gateway_websocket_execution_arn
  sqs_queue_image_notifications_arn = module.sns.aws_sqs_queue_image_notifications_arn
  aws_sqs_queue_image_notifications_id = module.sns.aws_sqs_queue_image_notifications_id
  aws_sns_topic_rekognition_video_updates_arn = module.sns.aws_sns_topic_rekognition_video_updates_arn
  aws_sqs_queue_rekognition_video_updates = module.sns.aws_sqs_queue_rekognition_video_updates
  aws_dynamodb_table_video_job_table_arn = module.dynamodb.aws_dynamodb_table_video_job_table_arn
  aws_sqs_queue_rekognition_text_updates = module.sns.aws_sqs_queue_rekognition_text_updates
}

module "cloudfront" {
  source = "./modules/cloudfront"
   providers = {
    aws = aws
    aws.us_east_1 = aws.us_east_1
  }
  website_bucket_name = module.s3.website_bucket_name
  data_aws_s3_bucket_website_id_bucket_regional_domain_name = module.s3.data_aws_s3_bucket_website_id_bucket_regional_domain_name
  aws_acm_certificate_validation_certificate_arn = module.route_53.aws_acm_certificate_validation_certificate_arn
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
  sqs_queue_name = module.sns.sqs_queue_name
  aws_region = var.aws_region
  aws_sqs_queue_image_notifications_name = module.sns.aws_sqs_queue_image_notifications_name
  aws_sns_topic_dlq_alert_arn = module.sns.aws_sns_topic_dlq_alert_arn
  aws_sqs_queue_dead_letter_queue_name = module.sns.aws_sqs_queue_dead_letter_queue_name
  aws_lambda_function_rekognition_consumer_function_name = local.rekognition_lambda_name
}

module "sns" {
  source = "./modules/sns"
  video_proccessing_arn = module.lambda.aws_lambda_function_video_proccessing_arn
}

module "route_53" {
  source = "./modules/route_53"
   providers = {
    aws = aws
    aws.us_east_1 = aws.us_east_1
  }
  aws_cloudfront_distribution_domain_name = module.cloudfront.aws_cloudfront_distribution_domain_name
  aws_cloudfront_distribution_hosted_zone_id = module.cloudfront.aws_cloudfront_distribution_hosted_zone_id
  aws_acm_certificate_website_arn = module.cloudfront.certificate_arn
  aws_acm_certificate_website = module.cloudfront.aws_acm_certificate_website

}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "ec2" {
  source = "./modules/ec2"
  aws_region = var.aws_region
  iam_instance_profile = module.iam.aws_iam_instance_profile_yace
  tags = {
    project = "rekognition-infrastructure"
  }
}