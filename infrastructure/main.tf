locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
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

resource "aws_s3_bucket_cors_configuration" "image_bucket" {
  bucket = aws_s3_bucket.image_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "image_bucket" {
  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                      = "${var.sqs_queue_name}-dead-letter"
  message_retention_seconds = 1209600
  tags                      = local.lambda_tags
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "image_notifications" {
  name                       = var.sqs_queue_name
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  sqs_managed_sse_enabled    = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 3
  })
  tags = local.lambda_tags
}

resource "aws_sqs_queue_policy" "allow_s3_send_message" {
  queue_url = aws_sqs_queue.image_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3EventDelivery"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.image_notifications.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.image_bucket.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "image_upload" {
  bucket = aws_s3_bucket.image_bucket.id

  queue {
    queue_arn = aws_sqs_queue.image_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_send_message]
}

resource "aws_iam_role" "presigned_url_lambda_role" {
  name = "${var.presigned_url_lambda_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.lambda_tags
}

resource "aws_iam_role_policy" "presigned_url_lambda_policy" {
  name = "${var.presigned_url_lambda_name}-policy"
  role = aws_iam_role.presigned_url_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.image_bucket.arn}/*",
          "${aws_s3_bucket.image_bucket.arn}/results/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "${aws_s3_bucket.image_bucket.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role" "rekognition_lambda_role" {
  name = "${var.rekognition_lambda_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.lambda_tags
}

resource "aws_iam_role_policy" "rekognition_lambda_policy" {
  name = "${var.rekognition_lambda_name}-policy"
  role = aws_iam_role.rekognition_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:RecognizeCelebrities"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.image_bucket.arn}/results/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.image_notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "presigned_url_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/pre_signed_url"
  output_path = "${path.module}/lambda/pre_signed_url.zip"
}

data "archive_file" "rekognition_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/rekognition_consumer"
  output_path = "${path.module}/lambda/rekognition_consumer.zip"
}

resource "aws_lambda_function" "presigned_url" {
  function_name    = var.presigned_url_lambda_name
  filename         = data.archive_file.presigned_url_lambda.output_path
  source_code_hash = data.archive_file.presigned_url_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.presigned_url_lambda_role.arn

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
      UPLOAD_PREFIX  = var.upload_prefix
    }
  }

  tags = local.lambda_tags
}

resource "aws_lambda_function" "rekognition_consumer" {
  function_name    = var.rekognition_lambda_name
  filename         = data.archive_file.rekognition_lambda.output_path
  source_code_hash = data.archive_file.rekognition_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.rekognition_lambda_role.arn

  environment {
    variables = {
      IMAGE_BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
    }
  }

  tags = local.lambda_tags
}

resource "aws_lambda_event_source_mapping" "sqs_to_rekognition" {
  event_source_arn = aws_sqs_queue.image_notifications.arn
  function_name    = aws_lambda_function.rekognition_consumer.arn
  enabled          = true
  batch_size       = 1
}

resource "aws_sns_topic" "dlq_alert" {
  name = "${var.sqs_queue_name}-dlq-alert"
}

resource "aws_sns_topic_subscription" "dlq_alert_email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.dlq_alert.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "dlq_message_alarm" {
  alarm_name          = "${var.sqs_queue_name}-dlq-message-alarm"
  alarm_description   = "Alert when any message remains in the dead-letter queue for over 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.5
  alarm_actions       = [aws_sns_topic.dlq_alert.arn]
  dimensions = {
    QueueName = aws_sqs_queue.dead_letter_queue.name
  }
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_dashboard" "rekognition_pipeline" {
  dashboard_name = "rekognition-pipeline"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.rekognition_consumer.function_name],
            [".", "Duration", "FunctionName", aws_lambda_function.rekognition_consumer.function_name]
          ]
          region = var.aws_region
          title  = "Rekognition Consumer Invocations / Duration"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.image_notifications.name]
          ]
          region = var.aws_region
          title  = "SQS Queue Length"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Rekognition", "Requests"]
          ]
          region = var.aws_region
          title  = "Rekognition API Requests"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          view = "singleValue"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.rekognition_consumer.function_name]
          ]
          region = var.aws_region
          title  = "Rekognition Consumer Errors"
        }
      }
    ]
  })
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allow_methods = ["OPTIONS", "GET", "POST"]
    allow_origins = ["*"]
    expose_headers = ["ETag"]
    max_age = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.presigned_url.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "label_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /labels"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "celebrity_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /celebrity"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "results_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /results"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw_invocation" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
