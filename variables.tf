variable "aws_region" {
  type = string
}

# used for lambda components and in user-agent for liquipedia api
variable "name" {
  type = string
}

# used in user-agent for liquipedia api
variable "author" {
  type = string
}

variable "teb_version" {
  type = string
}

# how often to check the liquipedia api
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
variable "update_rate" {
  type = string
}

variable "domain_name" {
  type = string
}