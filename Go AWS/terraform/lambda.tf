### 4 lambda and 4 archives for lambda ###
resource "aws_lambda_function" "lambda_ST" {
  filename         = data.archive_file.zip_the_go_lambda1.output_path
  function_name    = local.lambda1Name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = local.handler1
  runtime          = local.runtime
  source_code_hash = data.archive_file.zip_the_go_lambda1.output_base64sha256
}

resource "aws_lambda_function" "lambda_RC" {
  filename         = data.archive_file.zip_the_go_lambda2.output_path
  function_name    = local.lambda2Name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = local.handler2
  runtime          = local.runtime
  source_code_hash = data.archive_file.zip_the_go_lambda2.output_base64sha256
}

resource "aws_lambda_function" "lambda_RC_auth" {
  filename         = data.archive_file.zip_the_go_lambda3.output_path
  function_name    = local.lambda3Name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = local.handler3
  runtime          = local.runtime
  timeout          = 150
  source_code_hash = data.archive_file.zip_the_go_lambda3.output_base64sha256
  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.private_subnet : subnet.id]
    security_group_ids = [aws_default_security_group.default_security_group.id]
  }
}

resource "aws_lambda_function" "lambda_RC_from_api" {
  filename         = data.archive_file.zip_the_go_lambda4.output_path
  function_name    = local.lambda4Name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = local.handler4
  runtime          = local.runtime
  source_code_hash = data.archive_file.zip_the_go_lambda4.output_base64sha256

}


data "archive_file" "zip_the_go_lambda1" {
  type        = local.typeForArchive
  source_file = local.sourceDirArchive1
  output_path = local.fileNamePathLambda1
}

data "archive_file" "zip_the_go_lambda2" {
  type        = local.typeForArchive
  source_file = local.sourceDirArchive2
  output_path = local.fileNamePathLambda2
}

data "archive_file" "zip_the_go_lambda3" {
  type        = local.typeForArchive
  source_file = local.sourceDirArchive3
  output_path = local.fileNamePathLambda3
}

data "archive_file" "zip_the_go_lambda4" {
  type        = local.typeForArchive
  source_file = local.sourceDirArchive4
  output_path = local.fileNamePathLambda4
}