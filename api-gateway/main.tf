####
## Terraform providers
###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
  for_each = {
    for function in local.lambdas_output.aws_lambda_functions: "${function.function_name}" => function.invoke_arn
  }
  
  api_id           = aws_apigatewayv2_api.main_api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  description     = "Integration set by Terraform"

  integration_method = "POST"
  integration_uri    = each.value

  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

# Link API Gateway to Custom Authorizer (Lambda Function)
resource "aws_apigatewayv2_authorizer" "main_api_gateway_authorizer" {
  for_each = {
    for function in local.lambdas_output.aws_lambda_authorizers: "${function.function_name}" => function.invoke_arn
  }

  api_id                            = aws_apigatewayv2_api.main_api_gateway.id
  authorizer_type                   = var.api_gateway.authorizer.type
  authorizer_uri                    = each.value
  identity_sources                  = var.api_gateway.authorizer.identity_sources
  name                              = each.key
  authorizer_payload_format_version = var.api_gateway.authorizer.payload_format_version
}


# Create routes - linkage between HTTP calls and what functions & authorizers should be called
resource "aws_apigatewayv2_route" "main_api_gateway_route" {
  for_each = {
    for function in local.lambdas_output.aws_lambda_functions: "${function.function_name}" => aws_apigatewayv2_integration.main_api_gateway_integration[function.function_name].id
  }
  
  api_id    = aws_apigatewayv2_api.main_api_gateway.id
  route_key = "ANY /${each.key}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.main_api_gateway_authorizer[var.functions_auth[each.key].authorizer_function_name].id

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

# Create permissions for Gateway to be able to invoke Lambda Custom Authorizer Functions
resource "aws_lambda_permission" "api_authorizer_gw" {
  for_each = toset([ for function in local.lambdas_output.aws_lambda_authorizers: function.function_name ])
  
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main_api_gateway.execution_arn}/*/*"
}

###
# Resolve Cloud Watch for API Gateway
##
# resource "aws_cloudwatch_log_group" "main_api_gateway_cw_lg" {
#   name              = "API-Gateway-Execution-Logs_${aws_apigatewayv2_api.main_api_gateway.id}/${var.api_gateway.stage}"
#   retention_in_days = 1
# }

# # Create development stage
resource "aws_apigatewayv2_stage" "main_api_gateway_stage" {
  api_id = aws_apigatewayv2_api.main_api_gateway.id
  name   = var.api_gateway.stage

  auto_deploy = true

  # access_log_settings {
  #   destination_arn = aws_cloudwatch_log_group.main_api_gateway_cw_lg.arn
  #   format          = "$context.authorizer.error $context.authorizer.integrationStatus | $context.integration.error| $context.error.message $context.extendedRequestId $context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] $context.httpMethod $context.resourcePath $context.protocol $context.status $context.responseLength $context.requestId"
  # }

  # default_route_settings {
  #   logging_level            = "ERROR"
  #   detailed_metrics_enabled = true
  # }

  # depends_on = [aws_cloudwatch_log_group.main_api_gateway_cw_lg]
}


# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["apigateway.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }
# data "aws_iam_policy_document" "cloudwatch" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:DescribeLogGroups",
#       "logs:DescribeLogStreams",
#       "logs:PutLogEvents",
#       "logs:GetLogEvents",
#       "logs:FilterLogEvents",
#     ]

#     resources = ["*"]
#   }
# }

# resource "aws_iam_role" "cloudwatch" {
#   name               = "api_gateway_cloudwatch_global"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# resource "aws_api_gateway_account" "main_api_gateway_account" {
#   cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
# }

# resource "aws_iam_role_policy" "cloudwatch" {
#   name   = "default"
#   role   = aws_iam_role.cloudwatch.id
#   policy = data.aws_iam_policy_document.cloudwatch.json
# }
####
