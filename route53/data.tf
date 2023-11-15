data "terraform_remote_state" "webtier" {
  backend = "s3"
  config  = {
    bucket = var.webtier_data.bucket
    region = var.webtier_data.region
    key    = var.webtier_data.key
  }
}
