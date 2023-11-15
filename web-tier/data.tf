data "terraform_remote_state" "network" {
  backend = "s3"
  config  = {
    bucket = var.network_data.bucket
    region = var.network_data.region
    key    = var.network_data.key
  }
}

