data "terraform_remote_state" "lambdas" {
  backend = "s3"
  config  = {
    bucket = var.lambdas_data.bucket
    region = var.lambdas_data.region
    key    = var.lambdas_data.key
  }
}
