variable "api_name" {
  description = "Name of the API Gateway HTTP API."
  type        = string
  default     = "rekognition-presigned-url-api"
}


variable "api_gateway_access_log_settings" {
    description = "Access log settings for the API Gateway stage."
    type = map(string)
    default = {
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      caller         = "$context.identity.caller",
      user           = "$context.identity.user",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    }
}

// External variables

variable "integration_uri" {
    description = "ARN of the Lambda function that issues presigned URLs, used for API Gateway integration."
    type        = string
}

variable "aws_cloudwatch_log_group_api_gateway_logs_arn" {
    description = "ARN of the CloudWatch Log Group for API Gateway access logs."
    type        = string
}

variable "aws_iam_role_apigw_log_role_arn" {
    description = "ARN of the IAM role for API Gateway to write access logs to CloudWatch."
    type        = string
}


