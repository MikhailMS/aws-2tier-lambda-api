####
## Terraform providers
###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = var.bucket
    key    = var.key
    region = var.region
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-2"
  profile = "default"
}
####


####
## Configure AWS API Gateway to invoke AWS Lambda Functions
###
# Create API Gateway for AWS Lambda Functions
resource "aws_apigatewayv2_api" "main_api_gateway" {
  name          = var.api_gateway.name
  protocol_type = var.api_gateway.protocol_type
  version       = var.api_gateway.version

  description = var.api_gateway.description
}

# Create integrations - linkage between Gateway and Functions
resource "aws_apigatewayv2_integration" "main_api_gateway_integration" {
  for_each = {for function in local.lambdas_output.aws_lambda_functions: "${function.function_name}" => function.invoke_arn}
  
  api_id           = aws_apigatewayv2_api.main_api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  description     = "Integration from Terraform"

  integration_method = "POST"
  integration_uri    = each.value

  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

# Create routes - linkage between HTTP calls and what functions should be called
resource "aws_apigatewayv2_route" "main_api_gateway_route" {
  # for_each = zipmap(local.lambdas_output.aws_lambda_function_names, [for invoke_arn in local.lambdas_output.aws_lambda_function_invoke_arns: aws_apigatewayv2_integration.main_api_gateway_integration[invoke_arn].id])
  for_each = {
    for function in local.lambdas_output.aws_lambda_functions: "${function.function_name}" => aws_apigatewayv2_integration.main_api_gateway_integration[function.function_name].id
  }
  
  api_id    = aws_apigatewayv2_api.main_api_gateway.id
  # route_key = "ANY /medoviqTestFunction"
  route_key = "ANY /${each.key}"

  target = "integrations/${each.value}"
}

# Create permissions for Gateway to be able to invoke Lambda Functions
resource "aws_lambda_permission" "api_gw" {
  for_each = toset([ for function in local.lambdas_output.aws_lambda_functions: function.function_name ])
  
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main_api_gateway.execution_arn}/*/*"
}

# Link API Gateway to Custom Authorizer (Lambda Function)
resource "aws_apigatewayv2_authorizer" "main_api_gateway_authorizer" {
  for_each = {for function in local.lambdas_output.aws_lambda_authorizers: "${function.function_name}" => function.invoke_arn}
  
  api_id                            = aws_apigatewayv2_api.main_api_gateway.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = each.value
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "custom-authorizer"
  authorizer_payload_format_version = "2.0"
}

# Create permissions for Gateway to be able to invoke Lambda Functions
resource "aws_lambda_permission" "api_authorizer_gw" {
  for_each = toset([ for function in local.lambdas_output.aws_lambda_authorizers: function.function_name ])
  
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main_api_gateway.execution_arn}/*/*"
}

# Create development stage (not necessary for this exercise, but still good to know how)
resource "aws_apigatewayv2_stage" "main_api_gateway_stage" {
  api_id = aws_apigatewayv2_api.main_api_gateway.id
  name   = "development"

  auto_deploy = true
}
####
