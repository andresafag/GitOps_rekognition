variable "sqs_queue_name" {
    description = "Name of the SQS queue receiving S3 notifications."
    type        = string
}

variable "aws_region" {
    description = "AWS region to deploy resources into."
    type        = string
}

variable "aws_sqs_queue_image_notifications_name" {
    description = "Name of the SQS queue receiving image upload notifications."
    type        = string
}

variable "aws_sns_topic_dlq_alert_arn" {
    description = "ARN of the SNS topic for dead-letter queue alerts."
    type        = string
}

variable "aws_sqs_queue_dead_letter_queue_name" {
    description = "Name of the SQS dead-letter queue for failed messages."
    type        = string
}

variable "aws_lambda_function_rekognition_consumer_function_name" {
  description = "Name of the Rekognition consumer Lambda function."
  type = string
}