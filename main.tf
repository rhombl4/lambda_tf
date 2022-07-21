provider "aws" {
  region = local.region
}

locals {
  region = "eu-west-1"
}

resource "aws_iam_role" "lambda_role" {
  name               = "LambdaRoleForSnapshotCreation"
  assume_role_policy = <<EOF
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
EOF
  tags = {
    Managed-By = "Terraform"
  }
}

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "LambdaRoleForSnapshotCreationRolePolicy"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   },
   {
     "Action": [
       "DescribeDBInstances"
     ],
     "Resource": "arn:aws:rds:*:*:*",
     "Effect": "Allow"
   }

 ]
}
EOF
  tags = {
    Managed-By = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "app-zip" {
  type        = "zip"
  source_dir  = "${path.module}/py/"
  output_path = "${path.module}/py/app.zip"
}

variable "lambda_function_name" {
  default = "Test_Lambda"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "${path.module}/py/app.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello-app.lambda_handler"
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role, aws_iam_role_policy_attachment.lambda_logs,
  aws_cloudwatch_log_group.test_lambda]
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/py/app.zip")
  publish          = true
}

resource "aws_cloudwatch_log_group" "test_lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "Lambda_Logging_Policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}