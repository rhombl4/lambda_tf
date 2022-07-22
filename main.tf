provider "aws" {
  region = local.region
}

locals {
  region     = "eu-west-1"
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

### ROle and policies

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
       "rds:DescribeDBInstances"
     ],
     "Resource": "arn:aws:rds:*:*:*",
     "Effect": "Allow"
   },
   {
     "Action": [
        "rds:CopyDBSnapshot"
     ],
     "Effect": "Allow",
     "Resource": "arn:aws:rds:${local.region}:${local.account_id}:snapshot:*"
   },
   {
      "Action": [
        "rds:DeleteDBSnapshot"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:rds:${local.region}:${local.account_id}:snapshot:*monthly*"
   },
   {
      "Action": [
        "rds:DescribeDbSnapshots"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:rds:${local.region}:${local.account_id}:snapshot:*"
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

#### Source code

data "archive_file" "app-zip" {
  type        = "zip"
  source_dir  = "${path.module}/py/"
  output_path = "${path.module}/py/app.zip"
}

#### Lambda resources

variable "lambda_function_name" {
  default = "Test_Lambda"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "${path.module}/py/app.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello-app.lambda_handler"
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role,
  aws_cloudwatch_log_group.test_lambda]
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/py/app.zip")
  publish          = true
  tags = {
    Managed-By = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "test_lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
  tags = {
    Managed-By = "Terraform"
  }
}

#### Invoke lambda
resource "aws_iam_policy" "iam_invoke_lambda_policy" {

  name        = "InvokeTestLambdaPolicy"
  path        = "/"
  description = "AWS IAM Policy for lambda invocation"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1658522141421",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.terraform_lambda_func.arn}"
    }
  ]
}
EOF
  tags = {
    Managed-By = "Terraform"
  }
}
data "aws_iam_user" "lamtes" {
  user_name = "lamtes"
}

resource "aws_iam_user_policy_attachment" "attach_lambda_invoke_policy_to_user" {
  user       = data.aws_iam_user.lamtes.user_name
  policy_arn = aws_iam_policy.iam_invoke_lambda_policy.arn
}


#### Seed data

variable "test_db_name" {
  default = "testdb"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = var.test_db_name
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_snapshot" "test_snap" {

  db_instance_identifier = aws_db_instance.default.id
  db_snapshot_identifier = var.test_db_name
}

# resource "aws_db_snapshot_copy" "many_snapshots" {
#   count                         = 4
#   source_db_snapshot_identifier = aws_db_snapshot.test_snap.db_snapshot_arn
#   target_db_snapshot_identifier = "${var.test_db_name}-daily-${count.index}"
# }

