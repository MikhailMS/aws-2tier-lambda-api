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
## Configure AWS Lambda Functions
###
# Create dummy IAM policy for Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


# Create AWS Lambda Functions
resource "aws_lambda_function" "functions" {
  for_each = {
    for k, v in local.functions_array : "${v.terraform_name}" => v
  }

  function_name = each.value.function_name
  role          = aws_iam_role.iam_for_lambda.arn

  architectures = each.value.architectures
  description   = each.value.description
  handler       = each.value.handler
  runtime       = each.value.runtime

  s3_bucket = each.value.s3.bucket
  s3_key    = each.value.s3.key
}

# Resolve AWS Lambda Functions URLs
resource "aws_lambda_function_url" "function_url" {
  for_each = {
    for key, sub in aws_lambda_function.functions : key => sub
    if length(regexall("^function*", key)) > 0
  }

  function_name      = each.value.function_name
  authorization_type = "NONE"

  depends_on = [aws_lambda_function.functions]
}


# Create AWS Lambda Functions for custom auth
resource "aws_lambda_function" "custom_auth" {
  for_each = {
    for k, v in local.custom_auth_array : "${v.terraform_name}" => v
  }

  function_name = each.value.function_name
  role          = aws_iam_role.iam_for_lambda.arn

  architectures = each.value.architectures
  description   = each.value.description
  handler       = each.value.handler
  runtime       = each.value.runtime

  s3_bucket = each.value.s3.bucket
  s3_key    = each.value.s3.key
}

# Resolve AWS Lambda custom auth Functions URLs
resource "aws_lambda_function_url" "custom_auth_url" {
  for_each = {
    for key, sub in aws_lambda_function.custom_auth : key => sub
    if length(regexall("^custom_auth*", key)) > 0
  }

  function_name      = each.value.function_name
  authorization_type = "NONE"

  depends_on = [aws_lambda_function.functions]
}
#####
