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
variable "lambda" {
  description = "AWS Lambda function settings"
  type        = object({
    function_name = string,
    architectures = list(string),
    description   = string,
    handler       = string,
    runtime       = string,
    s3            = object({
      bucket = string,
      key    = string
    })
  })
}
