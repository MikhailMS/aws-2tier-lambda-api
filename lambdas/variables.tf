#=========== backend ==============
variable "bucket" {
  description = "backend bucket"
  type        = string
}
variable "key"    {
  description = "backend key"
  type        = string
}
variable "region" {
  description = "backend region"
  type        = string
}

#=========== lambda setting =======
variable "lambdas" {
  description = "Settings for AWS Lambda Functions"

  type = map(list(object(
    {
      function_name = string,
      architectures = list(string),
      description   = string,
      handler       = string,
      runtime       = string,
      s3            = object({
        bucket = string,
        key    = string
      }),

      terraform_name = string
    }))
  )

  validation {
    condition     = alltrue([for i in keys(var.lambdas) : alltrue([for j in lookup(var.lambdas, i) : contains(["x86_64", "arm64"], j.architectures[0])])])
    error_message = "Error! Only x86_64 or arm64 architectures are supported!"
  }
}
