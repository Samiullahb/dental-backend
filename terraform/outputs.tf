output "api_endpoint" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "appointments_table" {
  value = aws_dynamodb_table.appointments.name
}
