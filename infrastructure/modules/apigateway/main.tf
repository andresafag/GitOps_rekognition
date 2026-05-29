
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
  integration_uri        = var.integration_uri
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${var.api_name}-websocket"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_integration" "websocket_integration" {
  api_id                 = aws_apigatewayv2_api.websocket.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.integration_uri_ping_route_arn
  integration_method     = "POST"
  payload_format_version = "1.0"
  timeout_milliseconds = 29000
}

resource "aws_apigatewayv2_integration" "lambda_integration_rekognition_consumer" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.integration_uri
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

resource "aws_apigatewayv2_route" "videos_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /videos"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration_presigned_url.id}"
}

resource "aws_apigatewayv2_route" "text_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /text"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration_presigned_url.id}"
}


resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
  access_log_settings {
    destination_arn = var.aws_cloudwatch_log_group_api_gateway_logs_arn 
    format = jsonencode(var.api_gateway_access_log_settings)
  }
  depends_on = [aws_api_gateway_account.account]
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "$default"
  auto_deploy = true
  access_log_settings {
    destination_arn = var.aws_cloudwatch_log_group_api_gateway_logs_arn 
    format = jsonencode(var.api_gateway_access_log_settings)
  }

  depends_on = [aws_api_gateway_account.account] 
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = var.aws_iam_role_apigw_log_role_arn 
}

//-----------------------------


resource "aws_apigatewayv2_route" "ping_route" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "ping"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_integration.id}"
}

resource "aws_apigatewayv2_integration" "ping_integration" {
  api_id                 = aws_apigatewayv2_api.websocket.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.integration_uri
  integration_method     = "POST"
  payload_format_version = "1.0"
  timeout_milliseconds = 29000
}

