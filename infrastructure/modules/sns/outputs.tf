output "aws_sqs_queue_image_notifications_arn" {
    description = "ARN of the SQS queue receiving image upload notifications."
    value       = aws_sqs_queue.image_notifications.arn
}

output "sqs_queue_name" {
    description = "Name of the SQS queue receiving image upload notifications."
    value       = aws_sqs_queue.image_notifications.name
}

output "aws_sqs_queue_image_notifications_name" {
    description = "Name of the SQS queue receiving image upload notifications."
    value       = aws_sqs_queue.image_notifications.name
}

output "aws_sns_topic_dlq_alert_arn" {
    description = "ARN of the SNS topic for dead-letter queue alerts."
    value       = aws_sns_topic.dlq_alert.arn
}

output "aws_sqs_queue_dead_letter_queue_name" {
  description = "Name of the SQS dead-letter queue for failed messages."
  value = aws_sqs_queue.dead_letter_queue.name
}

output "aws_sqs_queue_image_notifications_id" {
  description = "ID of the SQS queue receiving image upload notifications."
  value       = aws_sqs_queue.image_notifications.id
}

output "aws_sns_topic_rekognition_video_updates_arn" {
  description = "ARN of the SNS topic for rekognition video updates."
  value       = aws_sns_topic.rekognition_video_updates.arn
}

output "aws_sqs_queue_rekognition_video_updates" {
  description = "ARN of the SQS queue for rekognition video updates."
  value       = aws_sqs_queue.aws_sqs_queue_rekognition_video_updates.arn
}

output "aws_sqs_queue_rekognition_text_updates" {
  value = aws_sqs_queue.aws_sqs_queue_rekognition_text_updates.arn
}

output "aws_sqs_queue_policy_allow_sns_send_message_queue_url" {
  description = "URL of the SQS queue policy that allows SNS to send messages."
  value       = aws_sqs_queue_policy.allow_sns_send_message.queue_url
}