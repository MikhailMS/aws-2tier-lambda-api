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
variable "ds_bucket" {
  description = "Lambda data source bucket"
  type        = string
}
variable "ds_key"    {
  description = "Lambda data source key"
  type        = string
}
variable "ds_region" {
  description = "Lambda data source region"
  type        = string
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
