variable "sqs_queue_name" {
  description = "Name of the SQS queue receiving S3 notifications."
  type        = string
  default     = "rekognition-image-queue"
}

variable "notification_email" {
  description = "Email address to receive DLQ alert notifications via SNS."
  type        = string
  default     = "andresfelipeacostagarcia34@gmail.com"
}

variable "video_proccessing_arn" {
  description = "ARN of the Lambda function that processes video analysis results."
  type        = string
}