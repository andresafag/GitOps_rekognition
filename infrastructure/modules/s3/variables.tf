variable "image_bucket_name" {
  description = "Name of the S3 bucket that stores uploaded images."
  type        = string
  default     = "rekognition-image-bucket123456"
}

variable "website_bucket_name" {
  description = "Name of the S3 bucket that hosts the static website."
  type        = string
  default     = "rekoglabelify.com"
}

variable "cors_rules" {
  description = "List of CORS rules for the S3 bucket."
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "HEAD", "DELETE"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
  
}

variable "allow_s3_send_message_policy" {
  description = "IAM policy that allows S3 to send messages to the SQS queue."
  type        = any
}

variable "sqs_queue_image_notifications_arn" {
  description = "ARN of the SQS queue receiving image upload notifications."
  type        = string
}

variable "aws_apigatewayv2_api_http_api_api_endpoint" {
  description = "HTTP API endpoint for requesting presigned upload URLs."
  type        = string
}

variable "aws_apigatewayv2_api_websocket_api_endpoint" {
  description = "WebSocket API endpoint for receiving real-time updates."
  type        = string
}

variable "websocket_stage_invoke_url" {
  description = "Invoke URL for the WebSocket API stage."
  type        = string
}