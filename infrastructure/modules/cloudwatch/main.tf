locals {
  lambda_tags = {
    project = "rekognition-infrastructure"
    owner   = "terraform"
  }
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
  alarm_actions       = [var.aws_sns_topic_dlq_alert_arn] 
  dimensions = {
    QueueName = var.aws_sqs_queue_dead_letter_queue_name 
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
            ["AWS/Lambda", "Invocations", "FunctionName", var.aws_lambda_function_rekognition_consumer_function_name], 
            [".", "Duration", "FunctionName", var.aws_lambda_function_rekognition_consumer_function_name] 
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
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.aws_sqs_queue_image_notifications_name] 
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
            ["AWS/Lambda", "Errors", "FunctionName", var.aws_lambda_function_rekognition_consumer_function_name] 
          ]
          region = var.aws_region
          title  = "Rekognition Consumer Errors"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/logs"
  retention_in_days = 14
  tags              = local.lambda_tags
}