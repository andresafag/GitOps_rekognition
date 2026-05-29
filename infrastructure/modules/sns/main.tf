locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
}

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


resource "aws_sns_topic" "dlq_alert" {
  name              = "${var.sqs_queue_name}-dlq-alert"
  kms_master_key_id = aws_kms_key.sns_encryption_key.arn
}

resource "aws_kms_key" "sns_encryption_key" {
  description             = "KMS key for encrypting SNS topic"
  deletion_window_in_days = 10

}

resource "aws_sns_topic_subscription" "dlq_alert_email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.dlq_alert.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic" "rekognition_video_updates" {
  name = "rekognition-video-analysis-topic"
}

resource "aws_sns_topic_subscription" "rekognition_video_updates_sqs" {
  topic_arn            = aws_sns_topic.rekognition_video_updates.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.aws_sqs_queue_rekognition_video_updates.arn
  raw_message_delivery = false
}

resource "aws_sqs_queue" "aws_sqs_queue_rekognition_video_updates" {
  name                       = "rekognition-video-updates-queue"
  visibility_timeout_seconds = 180
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  sqs_managed_sse_enabled    = true
}

resource "aws_sqs_queue_policy" "allow_sns_send_message" {
  queue_url = aws_sqs_queue.aws_sqs_queue_rekognition_video_updates.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSEventDelivery"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.aws_sqs_queue_rekognition_video_updates.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.rekognition_video_updates.arn
          }
        }
      }
    ]
  })
}


//------------------------------------------------------------

resource "aws_sns_topic" "rekognition_text_updates" {
  name = "rekognition-text-analysis-topic"
}

resource "aws_sns_topic_subscription" "rekognition_text_updates_sqs" {
  topic_arn            = aws_sns_topic.rekognition_text_updates.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.aws_sqs_queue_rekognition_text_updates.arn
  raw_message_delivery = false
}

resource "aws_sqs_queue" "aws_sqs_queue_rekognition_text_updates" {
  name                       = "rekognition-text-updates-queue"
  visibility_timeout_seconds = 180
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  sqs_managed_sse_enabled    = true
}

resource "aws_sqs_queue_policy" "allow_sns_send_message_text" {
  queue_url = aws_sqs_queue.aws_sqs_queue_rekognition_text_updates.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSEventDelivery"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.aws_sqs_queue_rekognition_text_updates.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.rekognition_text_updates.arn
          }
        }
      }
    ]
  })
}