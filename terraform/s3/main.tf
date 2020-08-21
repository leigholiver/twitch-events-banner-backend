variable "domain_name" {
  type = string
}

variable "content_dir" {
  type    = string
  default = "./src/s3"
}

output "arn" {
  value = aws_s3_bucket.s3.arn
}

resource "aws_s3_bucket" "s3" {
  bucket        = var.domain_name
  force_destroy = true
  acl           = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "null_resource" "upload_to_s3" {
  provisioner "local-exec" {
    command = "aws s3 sync --acl public-read ${var.content_dir} s3://${aws_s3_bucket.s3.id}"
  }
}