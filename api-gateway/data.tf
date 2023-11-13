data "terraform_remote_state" "lambdas" {
  backend = "s3"
  config  = {
    bucket = var.ds_bucket
    region = var.ds_region
    key    = var.ds_key
  }
}
