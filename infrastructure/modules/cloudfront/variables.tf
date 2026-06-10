variable "website_bucket_name" {
  description = "Name of the S3 bucket that hosts the static website."
  type        = string
}

variable "data_aws_s3_bucket_website_id_bucket_regional_domain_name" {
  description = "ID of the S3 bucket that hosts the static website."
  type        = string
}

variable "data_aws_s3_bucket_website_staging_bucket_regional_domain_name" {
  description = "Regional domain name of the staging S3 bucket for CloudFront origin."
  type        = string
  default     = ""
}

variable "aws_acm_certificate_validation_certificate_arn" {
  description = "ACM certificate validation for the CloudFront distribution."
  type        = any
}

variable "create_continuous_deployment_policy" {
  description = "Whether to create the CloudFront continuous deployment policy. Set to true in a second apply after the staging distribution is deployed."
  type        = bool
  default     = false
}