terraform {
  backend "s3" {
    bucket = "rh4-terraform"
    key    = "lambda_play/terraform.tfstate"
    region = "eu-west-1"
  }
}