variable "presigned_url_lambda_name" {
  description = "Name of the Lambda function that returns a presigned upload URL."
  type        = string
}

variable "rekognition_lambda_name" {
  description = "Name of the Lambda function that processes images via Amazon Rekognition."
  type        = string
}

variable "data_aws_s3_bucket_website_id" {
  description = "ID of the S3 bucket that hosts the static website."
  type        = string
}

variable "aws_cloudfront_origin_access_identity_iam_arn" {
  description = "ARN of the IAM role for the CloudFront origin access identity."
  type = string
}

variable "data_aws_s3_bucket_website_arn" {
  description = "ARN of the S3 bucket that hosts the static website."
  type        = string
}


variable "api_gateway_websocket_execution_arn" {
  description = "ARN of the API Gateway WebSocket execution"
  type        = string
}

variable "sqs_queue_image_notifications_arn" {
  description = "ARN of the SQS queue receiving image upload notifications."
  type        = string
}

variable "aws_sqs_queue_image_notifications_id" {
  description = "ID of the SQS queue receiving image upload notifications."
  type        = string
}

variable "aws_s3_bucket_image_bucket_arn" {
  description = "ARN of the S3 bucket that stores uploaded images."
  type        = string
}

variable "aws_sns_topic_rekognition_video_updates_arn" {
  description = "ARN of the SNS topic for Rekognition video updates."
  type        = string
}

variable "aws_sqs_queue_rekognition_video_updates" {
  description = "ARN of the SQS queue for Rekognition video updates."
  type        = string  
}

variable "aws_sqs_queue_rekognition_text_updates" {
  type = string
}

variable "aws_dynamodb_table_video_job_table_arn" {
  type = string
}