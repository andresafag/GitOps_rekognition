variable "website_bucket_name" {
  description = "Name of the S3 bucket that hosts the static website."
  type        = string
}

variable "data_aws_s3_bucket_website_id_bucket_regional_domain_name" {
  description = "ID of the S3 bucket that hosts the static website."
  type        = string
}

variable "aws_acm_certificate_validation_certificate_arn" {
  description = "ACM certificate validation for the CloudFront distribution."
  type        = any
}