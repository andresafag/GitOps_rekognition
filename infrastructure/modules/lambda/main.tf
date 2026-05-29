locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
}

data "archive_file" "presigned_url_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/pre_signed_url"
  output_path = "${path.module}/../../lambda/pre_signed_url.zip"
}

data "archive_file" "rekognition_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/rekognition_consumer"
  output_path = "${path.module}/../../lambda/rekognition_consumer.zip"
}


data "archive_file" "video_proccessing" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/video_proccessing"
  output_path = "${path.module}/../../lambda/video_proccessing.zip"
}

data "archive_file" "ping_pong" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/ping_pong"
  output_path = "${path.module}/../../lambda/ping_pong.zip"
}

resource "aws_lambda_function" "presigned_url" {
  function_name    = var.presigned_url_lambda_name
  filename         = data.archive_file.presigned_url_lambda.output_path
  source_code_hash = data.archive_file.presigned_url_lambda.output_base64sha256
  handler          = var.lambda_handler
  runtime          = var.runtime_version
  role             = var.role_presigned_url_arn

  environment {
    variables = {
      S3_BUCKET_NAME  = var.image_bucket_name 
      UPLOAD_PREFIX   = var.upload_prefix
      API_DOMAIN_NAME = "${replace(var.websocket_stage_invokeurl, "wss://", "https://")}"
    }
  }

  tags = local.lambda_tags
}

resource "aws_lambda_function" "video_proccessing" {
  function_name    = "video_proccessing"
  filename         = data.archive_file.video_proccessing.output_path
  source_code_hash = data.archive_file.video_proccessing.output_base64sha256
  handler          = var.lambda_handler
  runtime          = var.runtime_version
  role             = var.role_video_proccessing_arn

  environment {
    variables = {
      VIDEO_JOB_TABLE = var.aws_dynamodb_table_video_job_table_name
    }
  }
  tags = local.lambda_tags
}

resource "aws_lambda_function" "rekognition_consumer" {
  function_name    = var.rekognition_lambda_name
  filename         = data.archive_file.rekognition_lambda.output_path
  source_code_hash = data.archive_file.rekognition_lambda.output_base64sha256
  handler          = var.lambda_handler
  runtime          = var.runtime_version
  role             = var.role_rekognition_consumer_arn


  environment {
    variables = {
      IMAGE_BUCKET_NAME = var.image_bucket_name
      SNSTopicArn       = var.aws_sns_topic_rekognition_video_updates_arn
      IAM_ROLE_ARN      = var.aws_iam_role_rekognition_service_role
      VIDEO_UPDATES_SQS_QUEUE_URL = var.aws_sqs_queue_policy_allow_sns_send_message_queue_url
      VIDEO_JOB_TABLE = var.aws_dynamodb_table_video_job_table_name
    }
  }

  tags = local.lambda_tags
}


resource "aws_lambda_function" "ping_pong" {
  function_name    = "ping_pong_function"
  filename         = data.archive_file.ping_pong.output_path
  source_code_hash = data.archive_file.ping_pong.output_base64sha256
  handler          = var.lambda_handler
  runtime          = var.runtime_version
  role             = var.role_ping_pong 

  tags = local.lambda_tags
}

resource "aws_lambda_event_source_mapping" "sqs_to_rekognition" {
  event_source_arn = var.sqs_queue_image_notifications_arn 
  function_name    = aws_lambda_function.rekognition_consumer.arn
  enabled          = true
  batch_size       = 1
}

resource "aws_lambda_permission" "allow_apigw_invocation" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.presigned_url_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_http_execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_ping" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "ping_pong_function"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_websocket_execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_video_proccessing_invocation" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.video_proccessing.arn
  principal     = "sqs.amazonaws.com"
  source_arn    = var.aws_sqs_queue_rekognition_video_updates_arn
}

resource "aws_lambda_event_source_mapping" "sqs_to_video_processing" {
  event_source_arn = var.aws_sqs_queue_rekognition_video_updates_arn
  function_name    = aws_lambda_function.video_proccessing.arn
  enabled          = true
  batch_size       = 1
}
