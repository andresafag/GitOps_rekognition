variable "aws_cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution (e.g., d1234abcd.cloudfront.net)"
  type        = string
}

variable "aws_cloudfront_distribution_hosted_zone_id" {
  description = "Hosted zone ID for the CloudFront distribution (e.g., Z2FDTNDATAQYW2)"
  type        = string
}

variable "aws_acm_certificate_website_arn" {
  description = "ARN of the ACM certificate for the CloudFront distribution."
  type        = string
}

variable "aws_acm_certificate_website" {
  description = "ACM Certificate for the CloudFront distribution."
  type        = any
}
