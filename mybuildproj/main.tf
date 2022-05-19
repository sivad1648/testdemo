# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

provider "archive" {}

# Zip the function to be run
data "archive_file" "zip" {
  type        = "zip"
  source_file = "test_lambda.py"
  output_path = "test_lambda.zip"
}

#S3 bucket creation
resource "aws_s3_bucket" "b" {
  bucket = "IFF-DEV-bucket"

  tags = {
    Name        = "IFF_DEV_Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"       #######################Private or Public#####################
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_lambda_function" "lambda" {
  function_name = "test_lambda"

  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  role    = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "test_lambda.lambda_handler"
  runtime = "python3.6"

  environment {
    variables = {
      greeting = "Test"
    }
  }
}