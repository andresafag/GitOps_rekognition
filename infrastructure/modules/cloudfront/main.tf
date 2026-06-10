locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
}

resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "OAI for ${var.website_bucket_name}"
}

# SSL Certificate (must be in us-east-1 for CloudFront)
resource "aws_acm_certificate" "website" {
  provider                  = aws.us_east_1
  domain_name               = "rekoglabelify.com"
  subject_alternative_names = ["www.rekoglabelify.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.lambda_tags
}

resource "aws_cloudfront_distribution" "staging" {
  staging = true
  origin {
    domain_name = var.data_aws_s3_bucket_website_staging_bucket_regional_domain_name
    origin_id   = "S3-${var.website_bucket_name}-staging"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # No aliases here so CloudFront's default certificate is used for the distribution domain

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.website_bucket_name}-staging"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.lambda_tags
}

resource "aws_cloudfront_continuous_deployment_policy" "canary" {
  enabled = var.create_continuous_deployment_policy ? true : false
  depends_on = [null_resource.wait_for_staging_deployment]

  traffic_config {
    type = "SingleWeight"

    single_weight_config {
      weight = 0.15

      session_stickiness_config {
        idle_ttl    = 300
        maximum_ttl = 1440
      }
    }
  }

  staging_distribution_dns_names {
    quantity = 1
    items    = [aws_cloudfront_distribution.staging.domain_name]
  }
}

resource "null_resource" "wait_for_staging_deployment" {
  provisioner "local-exec" {
    command = <<EOT
COUNT=0
DIST_ID=${aws_cloudfront_distribution.staging.id}
while [ "$(aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.Status' --output text 2>/dev/null)" != "Deployed" ]; do
  sleep 10
  COUNT=$((COUNT+1))
  if [ $COUNT -gt 120 ]; then echo "Timeout waiting for CloudFront distribution $DIST_ID to deploy" >&2; exit 1; fi
done
EOT
    interpreter = ["/bin/sh", "-c"]
  }
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = var.data_aws_s3_bucket_website_id_bucket_regional_domain_name 
    origin_id   = "S3-${var.website_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["rekoglabelify.com", "www.rekoglabelify.com"]


  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.website_bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  viewer_certificate {
    acm_certificate_arn = var.aws_acm_certificate_validation_certificate_arn 
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.lambda_tags
}

resource "aws_wafv2_web_acl" "cloudfront_acl" {
  name        = "cloudfront-acl"
  description = "WAF ACL for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontACL"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "commonRuleSet"
      sampled_requests_enabled   = true
    }
  }

}
