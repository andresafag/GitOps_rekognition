output "api_name" {
  value = aws_apigatewayv2_api.http_api.name
}

output "api_url" {
  description = "HTTP API endpoint for requesting presigned upload URLs."
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_gateway_http_execution_arn" {
  value = aws_apigatewayv2_api.http_api.execution_arn
}

output "api_gateway_websocket_execution_arn" {
  value = aws_apigatewayv2_api.websocket.execution_arn
}

output "api_domain_name" {
  value = aws_apigatewayv2_api.websocket.api_endpoint
}

output "websocket_stage_invokeurl" {
  value = aws_apigatewayv2_stage.websocket_stage.invoke_url
}

output "websocket" {
  description = "websocket"
  value = aws_apigatewayv2_api.websocket.api_endpoint
}

output "websocket_url" {
  description = "wss endpoint"
  value = replace(aws_apigatewayv2_stage.websocket_stage.invoke_url, "wss://", "https://")
}

output "aws_apigatewayv2_api_http_api_api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "aws_apigatewayv2_api_websocket_api_endpoint" {
  value = aws_apigatewayv2_api.websocket.api_endpoint
}
