locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
}

data "aws_s3_bucket" "website" {
  bucket = var.website_bucket_name
}

resource "aws_s3_object" "website" {
  bucket       = var.website_bucket_name
  key          = "config.js"
  content_type = "application/javascript"
  content      = <<EOT
const CONFIG = {
  BASE_URL: "${var.aws_apigatewayv2_api_http_api_api_endpoint}",
  SOCKET: "${var.aws_apigatewayv2_api_websocket_api_endpoint}/$default",
  WSS: "${replace(var.websocket_stage_invoke_url, "wss://", "https://")}"
};
EOT

  # Use md5 for etag to detect content changes
  etag = md5(<<EOT
const CONFIG = {
  BASE_URL: "${var.aws_apigatewayv2_api_http_api_api_endpoint}",
  SOCKET: "${var.aws_apigatewayv2_api_websocket_api_endpoint}/$default",
  WSS: "${replace(var.websocket_stage_invoke_url, "wss://", "https://")}"
};
EOT
  )

  tags = local.lambda_tags
}


resource "aws_s3_bucket" "image_bucket" {
  bucket        = var.image_bucket_name
  force_destroy = true
  tags          = local.lambda_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "image_bucket" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_notification" "image_upload" {
  bucket = aws_s3_bucket.image_bucket.id

  queue {
    queue_arn = var.sqs_queue_image_notifications_arn
    events    = ["s3:ObjectCreated:Put"]
  }

  depends_on = [var.allow_s3_send_message_policy] 
}

resource "aws_s3_bucket_cors_configuration" "image_bucket" {
  bucket = aws_s3_bucket.image_bucket.id

  cors_rule {
    allowed_headers = var.cors_rules[0].allowed_headers
    allowed_methods = var.cors_rules[0].allowed_methods
    allowed_origins = var.cors_rules[0].allowed_origins
    expose_headers  = var.cors_rules[0].expose_headers
    max_age_seconds = var.cors_rules[0].max_age_seconds
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = data.aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}




resource "aws_s3_bucket_logging" "bucket_logs" {
  bucket        = aws_s3_bucket.image_bucket.id
  target_bucket = aws_s3_bucket.image_bucket.id
  target_prefix = "logs/"
}

# Staging website bucket for Canary/preview
resource "aws_s3_bucket" "website_staging" {
  bucket        = lower("s3-${var.website_bucket_name}-staging")
  force_destroy = true

  tags = local.lambda_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_staging" {
  bucket = aws_s3_bucket.website_staging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}