output "role_presigned_url" {
  value = aws_iam_role.presigned_url_lambda_role.arn
}

output "role_rekognition_consumer" {
  value = aws_iam_role.rekognition_lambda_role.arn
}

output "role_ping_pong" {
  value = aws_iam_role.ping_pong_role.arn
}

output "aws_sqs_queue_policy" {
  value = aws_sqs_queue_policy.allow_s3_send_message
}

output "aws_iam_role_apigw_log_role_arn" {
  value = aws_iam_role.apigw_log_role.arn
}


output "aws_iam_policy_rekognition_sns_policy" {
  value = aws_iam_policy.rekognition_sns_policy.arn
}

output "aws_iam_role_rekognition_service_role" {
  value = aws_iam_role.rekognition_service_role.arn
}

output "aws_iam_role_video_proccessing_lambda_role" {
  value = aws_iam_role.video_proccessing_lambda_role.arn
}

output "aws_iam_role_yace_ec2_role_arn" {
  value = aws_iam_role.yace_ec2_role.arn
}

output "aws_iam_instance_profile_yace" {
  value = aws_iam_instance_profile.yace_instance_profile.name
}