data "aws_caller_identity" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../server.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_dynamodb_table" "appointments" {
  name         = "${var.project_name}-appointments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute { name = "id" type = "S" }
  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-access"
  role = aws_iam_role.lambda.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "arn:aws:logs:*:*:*" },
    { Effect = "Allow", Action = ["dynamodb:PutItem", "dynamodb:Scan"], Resource = aws_dynamodb_table.appointments.arn }
  ] })
}

resource "aws_lambda_function" "api" {
  function_name    = var.project_name
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs22.x"
  handler          = "server.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  environment { variables = { TABLE_NAME = aws_dynamodb_table.appointments.name } }
}

resource "aws_apigatewayv2_api" "api" {
  name = var.project_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.api.id
  name = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api" {
  statement_id = "AllowApiGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
