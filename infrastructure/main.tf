locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
}

# API Gateway and related resources ---------------------------------------

resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers  = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allow_methods  = ["OPTIONS", "GET", "POST"]
    allow_origins  = ["*"]
    expose_headers = ["ETag"]
    max_age        = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration_presigned_url" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.presigned_url.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_api" "websocket" {
  name         = "${var.api_name}-websocket"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_integration" "websocket_integration" {
  api_id                 = aws_apigatewayv2_api.websocket.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.rekognition_consumer.arn
  integration_method     = "POST"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "lambda_integration_rekognition_consumer" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.rekognition_consumer.arn
  integration_method     = "GET"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "websocket_route" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "sockets"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_integration.id}"
}


resource "aws_apigatewayv2_route" "label_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /labels"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration_presigned_url.id}"
}

resource "aws_apigatewayv2_route" "celebrity_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /celebrity"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration_presigned_url.id}"
}


resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "$default"
  auto_deploy = true
}

# S3 Bucket for image uploads ---------------------------------------

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
    queue_arn = aws_sqs_queue.image_notifications.arn
    events    = ["s3:ObjectCreated:Put"]
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_send_message]
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

# SQS Queues for event-driven processing ---------------------------------------

resource "aws_sqs_queue" "dead_letter_queue" {
  name                      = "${var.sqs_queue_name}-dead-letter"
  message_retention_seconds = 1209600
  tags                      = local.lambda_tags
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "image_notifications" {
  name                       = var.sqs_queue_name
  visibility_timeout_seconds = 180
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  sqs_managed_sse_enabled    = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 3
  })
  tags = local.lambda_tags
}

# DynamoDB Table for storing Rekognition results

resource "aws_dynamodb_table" "rekognition_results" {
  name         = "mapping-routes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.lambda_tags
}

resource "aws_dynamodb_table" "connections" {
  name         = "websocket-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.lambda_tags
}
# Lambda functions and related resources ---------------------------------------

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

resource "local_file" "web_config" {
  # Ruta donde está tu código frontend
  filename = "${path.module}/../src/config.js" 
  
  content  = <<-EOT
    const CONFIG = {
      BASE_URL: "${aws_apigatewayv2_api.http_api.api_endpoint}",
      SOCKET: "${aws_apigatewayv2_api.websocket.api_endpoint}/$default",
      WSS: "${replace(aws_apigatewayv2_stage.websocket_stage.invoke_url, "wss://", "https://")}"
    };
  EOT
}

resource "aws_s3_object" "website" {
  bucket = var.website_bucket_name
  key    = "src/config.js"
  content = md5(<<EOT
    const CONFIG = {
      BASE_URL: "${aws_apigatewayv2_api.http_api.api_endpoint}",
      SOCKET: "${aws_apigatewayv2_api.websocket.api_endpoint}/$default",
      WSS: "${replace(aws_apigatewayv2_stage.websocket_stage.invoke_url, "wss://", "https://")}"
    };
  EOT
  )
  tags   = local.lambda_tags
  
}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = var.website_bucket_name
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket = var.website_bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_lambda_function" "presigned_url" {
  function_name    = var.presigned_url_lambda_name
  filename         = data.archive_file.presigned_url_lambda.output_path
  source_code_hash = data.archive_file.presigned_url_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "python3.10"
  role             = aws_iam_role.presigned_url_lambda_role.arn

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
      UPLOAD_PREFIX  = var.upload_prefix
      API_DOMAIN_NAME = "${replace(aws_apigatewayv2_stage.websocket_stage.invoke_url, "wss://", "https://")}"
    }
  }

  tags = local.lambda_tags
}

resource "aws_lambda_function" "rekognition_consumer" {
  function_name    = var.rekognition_lambda_name
  filename         = data.archive_file.rekognition_lambda.output_path
  source_code_hash = data.archive_file.rekognition_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "python3.10"
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

resource "aws_lambda_permission" "allow_apigw_invocation" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
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



# CloudWatch Alarms and Dashboard ---------------------------------------

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


#POLICIES AND ROLES ---------------------------------------

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
          "rekognition:RecognizeCelebrities",
          "rekognition:DetectModerationLabels"
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
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "${aws_s3_bucket.image_bucket.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = "${aws_dynamodb_table.rekognition_results.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:PutItem"
        ]
        Resource = [
          "${aws_dynamodb_table.rekognition_results.arn}/*",
          "${aws_dynamodb_table.connections.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke",
          "execute-api:ManageConnections",
          "execute-api:SendMessage",
          "execute-api:ReceiveMessage"
        ]
        Resource = "${aws_apigatewayv2_api.websocket.execution_arn}/*"
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
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [aws_dynamodb_table.rekognition_results.arn, aws_dynamodb_table.connections.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.image_notifications.arn
      }
    ]
  })
}