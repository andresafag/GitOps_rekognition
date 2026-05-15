output "aws_cloudwatch_log_group_api_gateway_logs_arn" {
    description = "ARN of the CloudWatch Log Group for API Gateway access logs."
    value       = aws_cloudwatch_log_group.api_gateway_logs.arn
}