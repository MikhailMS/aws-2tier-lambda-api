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

#=========== subnet ==============
variable "subnets" {
  description = "AWS Subnets"

  type = map(list(object(
    {
      availability_zone = string,
      cidr_block        = string,
      name              = string,
      tag_name          = string
    }))
  )

  validation {
    condition     = alltrue([for i in keys(var.subnets) : alltrue([for j in lookup(var.subnets, i) : contains(["eu-west-2a", "eu-west-2b", "eu-west-2c"], j.availability_zone)])])
    error_message = "Error! Only eu-west-2 a/b/c zones are supported!"
  }
}
