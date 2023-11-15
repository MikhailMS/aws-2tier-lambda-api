locals {
  subnets_array = flatten([for k, v in var.subnets : [for j in v : {
    availability_zone = j.availability_zone
    cidr_block        = j.cidr_block
    name              = j.name
    tag_name          = j.tag_name
    }
  ]])
}
