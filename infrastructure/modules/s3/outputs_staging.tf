output "website_staging_bucket_name" {
  description = "Name of the staging S3 bucket used for CloudFront staging origin."
  value       = aws_s3_bucket.website_staging.bucket
}

output "website_staging_bucket_arn" {
  description = "ARN of the staging S3 bucket used for CloudFront staging origin."
  value       = aws_s3_bucket.website_staging.arn
}

output "website_staging_bucket_regional_domain_name" {
  description = "Regional domain name of the staging S3 bucket for use as CloudFront origin."
  value       = aws_s3_bucket.website_staging.bucket_regional_domain_name
}
