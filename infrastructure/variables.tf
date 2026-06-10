variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "create_cloudfront_continuous_deployment_policy" {
  description = "When true, create the CloudFront continuous deployment policy in the cloudfront module. Used to run a second apply after distributions are deployed."
  type        = bool
  default     = false
}






