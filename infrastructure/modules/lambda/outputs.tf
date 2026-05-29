output "upload_prefix" {
  value = var.upload_prefix
}

output "runtime_version" {
  value = var.runtime_version
}

output "lambda_handler" {
  value = var.lambda_handler
}

output "aws_lambda_function_presigned_url_arn" {
  value = aws_lambda_function.presigned_url.arn
}

output "presigned_url_lambda_name" {
  description = "Name of the Lambda function that issues presigned URLs."
  value       = aws_lambda_function.presigned_url.function_name
}

output "aws_lambda_function_video_proccessing_arn" {
  value = aws_lambda_function.video_proccessing.arn
}

output "aws_lambda_function_ping_pong_arn" {
  value = aws_lambda_function.ping_pong.invoke_arn
}