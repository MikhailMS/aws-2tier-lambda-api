output "aws_lambda_functions" {
  value = [for k, v in var.lambdas["functions"]: aws_lambda_function.functions[v.terraform_name]]
}

output "aws_lambda_authorizers" {
  value = [for k, v in var.lambdas["custom_auth"]: aws_lambda_function.custom_auth[v.terraform_name]]
}
