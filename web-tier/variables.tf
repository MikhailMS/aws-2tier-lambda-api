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

#=========== network data ========
variable "network_data" {
  description = "Where to get network data from"
  type = object({
    bucket = string,
    region = string,
    key    = string
  })
}


#=========== TLS Cert Arn =========
variable "tls_cert_arn" {
  description = "TLS Certificate ARN identifier"
  type        = string
}

#=========== template settings ====
variable "launch_template_settings" {
  description = "Launch Template Settings"
  type        = object({
    name_prefix   = string,
    image_id      = string,
    instance_type = string,
    key_name      = string
  })
}

#=========== ecr settings ====
variable "ecr_settings" {
  description = "ECR Settings"
  type        = object({
    account_id = string,
    region     = string,
    repository = string
  })
}

