# build the package for deployment
resource "null_resource" "package_deps" {
  triggers = {
    reqs_changed = filebase64sha256("${var.source_dir}/requirements.txt")
  }

  provisioner "local-exec" {
    command = "pip install -r ${var.source_dir}/requirements.txt -t ${var.deps_dir}"
  }
}

resource "null_resource" "package_src" {
  triggers = {
    reqs_changed = filebase64sha256("${var.source_dir}/lambda_handler.py")
  }

  provisioner "local-exec" {
    command = "cp ${var.source_dir}/* ${var.deps_dir}"
  }

  depends_on = [null_resource.package_deps]
}

data "null_data_source" "wait_for_packaging" {
  inputs = {
    lambda_exporter_id = null_resource.package_src.id
    source_dir         = var.deps_dir
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = data.null_data_source.wait_for_packaging.outputs["source_dir"]
  output_path = var.lambda_zip_path
}

# the lambda
resource "aws_lambda_function" "lambda" {
  filename         = var.lambda_zip_path
  function_name    = "${var.name}_lambda"
  role             = aws_iam_role.role.arn
  handler          = "lambda_handler.lambda_handler"
  runtime          = "python3.7"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  timeout          = 5
  environment {
    variables = {
      NAME        = var.name
      AUTHOR      = var.author
      VERSION     = var.teb_version
      BUCKET_NAME = var.domain_name
    }
  }
  depends_on = [data.archive_file.lambda_zip]
}

# event rule
resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = "${var.name}_event_rule"
  schedule_expression = var.update_rate
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule = aws_cloudwatch_event_rule.event_rule.name
  arn  = aws_lambda_function.lambda.arn
}

# permissions
resource "aws_lambda_permission" "event_permission" {
  statement_id  = "${var.name}_permission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
}

resource "aws_iam_role" "role" {
  name = "${var.name}_lambda_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

# permission to write to the s3 bucket
resource "aws_iam_policy" "policy" {
  name   = "${var.name}_s3_policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": ["${var.bucket_arn}/*"]
    }
  ]
} 
POLICY
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}