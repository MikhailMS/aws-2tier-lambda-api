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

#=========== webtier data ========
variable "webtier_data" {
  description = "Where to get Web Tier data from"
  type = object({
    bucket = string,
    region = string,
    key    = string
  })
}

#=========== route 53 setting =====
variable "route53" {
  description = "Route53 settings"
  type        = object({
    zone_id     = string,
    record_name = string,
    record_type = string,
  })
}
