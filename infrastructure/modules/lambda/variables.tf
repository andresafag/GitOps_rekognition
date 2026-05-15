variable "presigned_url_lambda_name" {
  description = "Name of the Lambda function that returns a presigned upload URL."
  type        = string
}

variable "rekognition_lambda_name" {
  description = "Name of the Lambda function that processes images via Amazon Rekognition."
  type        = string
}

# variable "video_proccessing_lambda_name" {
#   description = "Name of the Lambda function that processes videos."
#   type        = string
# }

variable "upload_prefix" {
  description = "Optional S3 key prefix for uploaded images."
  type        = string
  default     = "uploads/"
}

variable "runtime_version" {
    description = "Runtime version for the Lambda functions."
    type        = string
    default     = "python3.10"
}

variable "lambda_handler" {
    description = "Handler for the presigned URL Lambda function."
    type        = string
    default     = "index.handler"
}


// External variables

variable "api_domain_name" {
    description = "Custom domain name for the API Gateway."
    type        = string
}

variable "role_presigned_url_arn" {
    description = "IAM role for the presigned URL Lambda function."
    type        = string

}

variable "role_rekognition_consumer_arn" {
    description = "IAM role for the Rekognition consumer Lambda function."
    type        = string
}

variable "image_bucket_name" {
    description = "Name of the S3 bucket for image storage."
    type        = string
}

variable "websocket_stage_invokeurl" {
    description = "Invoke URL for the WebSocket API stage."
    type        = string
}

variable "api_gateway_http_execution_arn" {
    description = "ARN of the API Gateway HTTP execution for Lambda permissions."
    type        = string
}

variable "sqs_queue_image_notifications_arn" {
    description = "ARN of the SQS queue for image upload notifications."
    type        = string
}

variable "aws_iam_role_rekognition_service_role" {
  type = string
}

variable "aws_sns_topic_rekognition_video_updates_arn" {
  type = string
}

variable "role_video_proccessing_arn" {
    description = "IAM role for the video processing Lambda function."
    type        = string
}

variable "aws_sqs_queue_rekognition_video_updates_arn" {
  description = "ARN of the SQS queue for rekognition video updates."
  type        = string
}

variable "aws_sqs_queue_policy_allow_sns_send_message_queue_url" {
    description = "URL of the SQS queue policy that allows SNS to send messages."
    type        = string
}

variable "aws_dynamodb_table_video_job_table_name" {
  type = string
}

