output "lambda_arn" {
  value = aws_lambda_function.terraform_lambda_func.arn
}
output "lambda_version" {
  value = aws_lambda_function.terraform_lambda_func.version
}
output "lamtes_user" {
  value = data.aws_iam_user.lamtes.arn
}