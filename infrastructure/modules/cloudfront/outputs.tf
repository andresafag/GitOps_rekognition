output "aws_cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.website.domain_name
}

output "aws_cloudfront_distribution_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "aws_cloudfront_origin_access_identity_iam_arn" {
  description = "IAM ARN of the CloudFront origin access identity."
  value       = aws_cloudfront_origin_access_identity.website.iam_arn
}

output "aws_acm_certificate_website_arn" {
  description = "ARN of the ACM certificate for the CloudFront distribution."
  value       = aws_acm_certificate.website.arn
}

output "aws_acm_certificate_website_domain_validation_options" {
  description = "Domain validation options for the ACM certificate."
  value       = aws_acm_certificate.website.domain_validation_options
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "staging_distribution_id" {
  description = "CloudFront Staging Distribution ID"
  value       = aws_cloudfront_distribution.staging.id
}

output "staging_domain_name" {
  description = "CloudFront Staging Distribution Domain Name"
  value       = aws_cloudfront_distribution.staging.domain_name
}

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.website.arn
}

output "aws_acm_certificate_website" {
  description = "ACM Certificate for the CloudFront distribution."
  value       = aws_acm_certificate.website.domain_validation_options
}