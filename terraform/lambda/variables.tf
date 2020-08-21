variable "bucket_arn" {}

variable "domain_name" {
  type = string
}

variable "name" {
  type = string
}

variable "teb_version" {
  type = string
}

variable "author" {
  type = string
}

# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
variable "update_rate" {
  type    = string
  default = "rate(30 minutes)"
}

variable "source_dir" {
  type    = string
  default = "./src/lambda"
}

variable "lambda_zip_path" {
  type    = string
  default = "./build/lambda.zip"
}

variable "deps_dir" {
  type    = string
  default = "./build/packages"
}