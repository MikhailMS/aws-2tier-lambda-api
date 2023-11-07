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

resource "aws_lambda_function" "test_lambda" {
  function_name = var.lambda.function_name
  role          = aws_iam_role.iam_for_lambda.arn

  architectures = var.lambda.architectures
  description   = var.lambda.description
  handler       = var.lambda.handler
  runtime       = var.lambda.runtime

  s3_bucket = var.lambda.s3.bucket
  s3_key    = var.lambda.s3.key
}

resource "aws_lambda_function_url" "test_latest" {
  function_name      = aws_lambda_function.test_lambda.function_name
  authorization_type = "NONE"
}
