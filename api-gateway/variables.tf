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

#=========== lambda's data ========
variable "lambdas_data" {
  description = "Where to get lambdas data from"
  type = object({
    bucket = string,
    region = string,
    key    = string
  })
}

#=========== lambda's setting =====
variable "api_gateway" {
  description = "AWS Lambda function settings"
  type        = object({
    description   = string,
    name          = string,
    protocol_type = string,
    version       = number
  })
}

#=========== lambda's auth ========
variable "functions_auth" {
  description = "Map AWS Lambda Functions onto custom authorizers"

  type = map(object(
    {
      authorizer_function_name = string,
    })
  )
}
