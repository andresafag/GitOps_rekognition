variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "image_bucket_name" {
  description = "Name of the S3 bucket that stores uploaded images."
  type        = string
  default     = "rekognition-image-bucket123456"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue receiving S3 notifications."
  type        = string
  default     = "rekognition-image-queue"
}

variable "presigned_url_lambda_name" {
  description = "Name of the Lambda function that returns a presigned upload URL."
  type        = string
  default     = "rekognition-presigned-url-lambda"
}

variable "rekognition_lambda_name" {
  description = "Name of the Lambda function that processes images via Amazon Rekognition."
  type        = string
  default     = "rekognition-consumer-lambda"
}

variable "api_name" {
  description = "Name of the API Gateway HTTP API."
  type        = string
  default     = "rekognition-presigned-url-api"
}

variable "upload_prefix" {
  description = "Optional S3 key prefix for uploaded images."
  type        = string
  default     = "uploads/"
}

variable "notification_email" {
  description = "Email address to receive DLQ alert notifications via SNS."
  type        = string
  default     = "andresfelipeacostagarcia34@gmail.com"
}

variable "website_bucket_name" {
  description = "Name of the S3 bucket that hosts the static website."
  type        = string
  default     = "website-documentsrek-123"
}
