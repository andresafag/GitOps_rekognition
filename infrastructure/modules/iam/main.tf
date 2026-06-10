locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
}

# POLICIES -----------------------------------------------------------

resource "aws_s3_bucket_policy" "website" {
  bucket = var.data_aws_s3_bucket_website_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.aws_cloudfront_origin_access_identity_iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${var.data_aws_s3_bucket_website_arn}/*" 
      }
    ]
  })
}

# Policy for staging website bucket (allow CloudFront OAI to read objects)
resource "aws_s3_bucket_policy" "website_staging" {
  count  = var.website_staging_bucket_name != "" ? 1 : 0
  bucket = var.website_staging_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccessStaging"
        Effect = "Allow"
        Principal = {
          AWS = var.aws_cloudfront_origin_access_identity_iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${var.website_staging_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "video_proccessing_lambda_policy" {
  name = "video_proccessing_lambda_policy"
  role = aws_iam_role.video_proccessing_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rekognition:GetLabelDetection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "${var.aws_dynamodb_table_video_job_table_arn}"
      },
            {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke",
          "execute-api:ManageConnections",
          "execute-api:SendMessage",
          "execute-api:ReceiveMessage"
        ]
        Resource = "${var.api_gateway_websocket_execution_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.aws_sqs_queue_rekognition_video_updates
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

resource "aws_iam_role_policy" "ping_pong_lambda_policy" {
  name = "pingpong-policy"
  role = aws_iam_role.ping_pong_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "${var.api_gateway_websocket_execution_arn}/*"
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
          "rekognition:DetectModerationLabels",
          "rekognition:StartLabelDetection",
          "rekognition:GetLabelDetection",
          "rekognition:DetectText"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObjectMetadata",
          "s3:DeleteObject"
        ]
        Resource = "${var.aws_s3_bucket_image_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke",
          "execute-api:ManageConnections",
          "execute-api:SendMessage",
          "execute-api:ReceiveMessage"
        ]
        Resource = "${var.api_gateway_websocket_execution_arn}/*"
      },
      {
          Effect = "Allow"
          Action = [
            "sns:Publish"
          ]
          Resource = var.aws_sns_topic_rekognition_video_updates_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_image_notifications_arn
      },
      {
        Effect = "Allow"
        Action = "sqs:SendMessage"
        Resource = var.aws_sqs_queue_rekognition_video_updates
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = var.aws_dynamodb_table_video_job_table_arn
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.rekognition_service_role.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "rekognition.amazonaws.com"
          }
        }
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

resource "aws_iam_role_policy" "rekognition_sns_policy" {
  name = "RekognitionSNSPublish"
  role = aws_iam_role.rekognition_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = var.aws_sns_topic_rekognition_video_updates_arn
      }
    ]
  })
}


resource "aws_sqs_queue_policy" "allow_s3_send_message" {
  queue_url = var.aws_sqs_queue_image_notifications_id

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
        Resource = var.sqs_queue_image_notifications_arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.aws_s3_bucket_image_bucket_arn
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
          "${var.aws_s3_bucket_image_bucket_arn}/*",
          "${var.aws_s3_bucket_image_bucket_arn}/results/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "${var.aws_s3_bucket_image_bucket_arn}"
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
          "sqs:SendMessage"
        ]
        Resource = var.sqs_queue_image_notifications_arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "default" {
  arn = var.aws_sns_topic_rekognition_video_updates_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRekognitionPublish"
        Effect = "Allow"
        Principal = {
          Service = "rekognition.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = var.aws_sns_topic_rekognition_video_updates_arn
      }
    ]
  })
}


resource "aws_iam_policy" "rekognition_sns_policy" {
  name        = "RekognitionSNSPublishPolicy"
  description = "Permite a Rekognition enviar notificaciones a SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = var.aws_sns_topic_rekognition_video_updates_arn
      },
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${var.aws_s3_bucket_image_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy" "rekognition_start_label_detection_policy" {
  name        = "RekognitionStartLabelDetectionPolicy"
  description = "Permite a Rekognition iniciar detección de etiquetas en videos"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "rekognition:StartLabelDetection"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${var.aws_s3_bucket_image_bucket_arn}/*"
      }
    ]
  })
  
}


# ROLES -----------------------------------------------------------

resource "aws_iam_role" "apigw_log_role" {
  name = "apigw-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "video_proccessing_lambda_role" {
  name = "video_proccessing_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  
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


resource "aws_iam_role" "ping_pong_role" {
  name = "pingpong-role"

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


resource "aws_iam_role" "rekognition_service_role" {
  name = "RekognitionServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rekognition.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#  ATTACHMENTS -----------------------------------------------------------

resource "aws_iam_role_policy_attachment" "rekognition_attach" {
  role       = aws_iam_role.rekognition_service_role.name
  policy_arn = aws_iam_policy.rekognition_sns_policy.arn
}

resource "aws_iam_role_policy_attachment" "apigw_log_attach" {
  role       = aws_iam_role.apigw_log_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "rekognition_start_label_detection_attach" {
  role       = aws_iam_role.rekognition_service_role.name
  policy_arn = aws_iam_policy.rekognition_start_label_detection_policy.arn
}

# YACE / EC2 exporter role and policy ---------------------------------
resource "aws_iam_policy" "yace_cloudwatch_policy" {
  name        = "YACECloudWatchReadPolicy"
  description = "Allows YACE (running on EC2) to read CloudWatch metrics and list Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListDashboards",
          "cloudwatch:DescribeAlarmsForMetric"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:GetQueryResults",
          "logs:StartQuery"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunctionConfiguration",
          "lambda:ListTags",
          "lambda:GetPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "yace_ec2_role" {
  name = "yace-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "yace_policy_attach" {
  role       = aws_iam_role.yace_ec2_role.name
  policy_arn = aws_iam_policy.yace_cloudwatch_policy.arn
}

// Create instance profile only when the user did not provide an existing name
resource "aws_iam_instance_profile" "yace_instance_profile" {
  count = var.yace_instance_profile_name == "" && var.create_yace_instance_profile ? 1 : 0
  name  = "yace-instance-profile"
  role  = aws_iam_role.yace_ec2_role.name
}

# If user supplied an existing instance profile name, reference it
data "aws_iam_instance_profile" "yace_existing" {
  count = var.yace_instance_profile_name != "" ? 1 : 0
  name  = var.yace_instance_profile_name
}

# Create Prometheus instance profile only when the user did not provide an existing name
resource "aws_iam_instance_profile" "prometheus_profile" {
  count = var.prometheus_instance_profile_name == "" && var.create_prometheus_instance_profile ? 1 : 0
  name  = "prometheus-instance-profile"
  role  = aws_iam_role.yace_ec2_role.name
}

# If user supplied an existing instance profile name for Prometheus, reference it
data "aws_iam_instance_profile" "prometheus_existing" {
  count = var.prometheus_instance_profile_name != "" ? 1 : 0
  name  = var.prometheus_instance_profile_name
}