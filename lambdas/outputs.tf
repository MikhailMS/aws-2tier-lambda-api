output "aws_lambda_function_arns" {
  value = [for k, v in var.lambdas["functions"]: aws_lambda_function.functions[v.terraform_name].arn]
}

output "aws_lambda_function_invoke_arns" {
  value = [for k, v in var.lambdas["functions"]: aws_lambda_function.functions[v.terraform_name].invoke_arn]
}

output "aws_lambda_function_urls" {
  value = [for k, v in var.lambdas["functions"]: aws_lambda_function_url.function_url[v.terraform_name].function_url]
}

output "aws_lambda_function_names" {
  value = [for k, v in var.lambdas["functions"]: v.function_name]
}
