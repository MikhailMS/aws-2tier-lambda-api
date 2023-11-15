####
## Terraform providers
###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = var.bucket
    key    = var.key
    region = var.region
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-2"
  profile = "default"
}
####


# Create & resolve Route53 record to make use of HTTPS DNS
resource "aws_route53_record" "www" {
  zone_id = var.route53.zone_id

  name = var.route53.record_name
  type = var.route53.record_type

  alias {
    name                   = local.webtier_output.lb.dns_name
    zone_id                = local.webtier_output.lb.zone_id
    evaluate_target_health = true
  }
}

