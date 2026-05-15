output "image_bucket_name" {
  description = "Name of the S3 bucket that stores uploaded images."
  value       = aws_s3_bucket.image_bucket.bucket
}

output "website_bucket_name" {
  description = "Name of the S3 bucket that hosts the static website."
  value       = var.website_bucket_name
}

output "data_aws_s3_bucket_website_id_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket that hosts the static website."
  value       = data.aws_s3_bucket.website.bucket_regional_domain_name
}

output "data_aws_s3_bucket_website_id" {
  description = "ID of the S3 bucket that hosts the static website."
  value       = data.aws_s3_bucket.website.id
}

output "data_aws_s3_bucket_website_arn" {
  description = "ARN of the S3 bucket that hosts the static website."
  value = data.aws_s3_bucket.website.arn
}

output "aws_s3_bucket_image_bucket_arn" {
  description = "ARN of the S3 bucket that stores uploaded images."
  value = aws_s3_bucket.image_bucket.arn
}

