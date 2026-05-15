output "aws_acm_certificate_validation_certificate_arn" {
    description = "ACM certificate validation for the CloudFront distribution."
    value       = aws_acm_certificate_validation.website.certificate_arn
}

