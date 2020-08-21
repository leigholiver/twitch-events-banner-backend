terraform {
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

module "bucket" {
  source      = "./terraform/s3"
  domain_name = var.domain_name
}

module "lambda" {
  source      = "./terraform/lambda"
  name        = var.name
  author      = var.author
  teb_version = var.teb_version
  domain_name = var.domain_name
  update_rate = var.update_rate
  bucket_arn  = module.bucket.arn
}