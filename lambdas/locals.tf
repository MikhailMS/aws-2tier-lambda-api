locals {
  functions_array   = var.lambdas["functions"]
  custom_auth_array = var.lambdas["custom_auth"]

  # functions_array = flatten([for k, v in var.lambdas["functions"] : [for j in v : {
  #   function_name = j.function_name

  #   architectures = j.architectures
  #   description   = j.description
  #   handler       = j.handler
  #   runtime       = j.runtime

  #   s3 = j.s3

  #   terraform_name = j.terraform_name
  #   }
  # ]])

  # custom_auth_array = flatten([for k, v in var.lambdas["custom_auth"] : [for j in v : {
  #   function_name = j.function_name

  #   architectures = j.architectures
  #   description   = j.description
  #   handler       = j.handler
  #   runtime       = j.runtime

  #   s3 = j.s3

  #   terraform_name = j.terraform_name
  #   }
  # ]])
}
