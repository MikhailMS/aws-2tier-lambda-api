locals {
  functions_array = flatten([for k, v in var.lambdas : [for j in v : {
    function_name = j.function_name

    architectures = j.architectures
    description   = j.description
    handler       = j.handler
    runtime       = j.runtime

    s3 = j.s3

    terraform_name = j.terraform_name
    }
  ]])
}
