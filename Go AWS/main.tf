locals {
  #lambda locals#
  lambda1Name = "lambda_ST"
  lambda2Name = "lambda_RC"
  handler1 = "lambda_sender"
  handler2 = "lambda_receiver"
  runtime = "go1.x"
  typeForArchive = "zip"
  sourceDirArchive1 = "${path.module}/bin/lambda_sender"
  sourceDirArchive2 = "${path.module}/bin/lambda_receiver"
  fileNamePathLambda1 = "${path.module}/bin/lambda_sender.zip"
  fileNamePathLambda2 = "${path.module}/bin/lambda_receiver.zip"
  #kinesis locals#
  kinesisName       = "kinesis_stream"
  shardCount        = 1
  retentionPeriod   = 48
  shardLevelMetrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]
  startingPosition = "LATEST"

}


### 2 lambda and 2 archives for lambda ###
resource "aws_lambda_function" "lambda_ST" {
  filename      = data.archive_file.zip_the_go_lambda1.output_path
  function_name = local.lambda1Name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = local.handler1
  runtime       = local.runtime
}

resource "aws_lambda_function" "lambda_RC" {
  filename      = data.archive_file.zip_the_go_lambda2.output_path
  function_name = local.lambda2Name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = local.handler2
  runtime       = local.runtime
}



data "archive_file" "zip_the_go_lambda1" {
  type        = local.typeForArchive
  source_file  = local.sourceDirArchive1
  output_path = local.fileNamePathLambda1
}

data "archive_file" "zip_the_go_lambda2" {
  type        = local.typeForArchive
  source_file  = local.sourceDirArchive2
  output_path = local.fileNamePathLambda2
}
### 1 Kinesis and 1 trigger from lambda###
resource "aws_kinesis_stream" "kinesis_stream" {
  name                = local.kinesisName
  shard_count         = local.shardCount
  retention_period    = local.retentionPeriod
  shard_level_metrics = local.shardLevelMetrics
}

resource "aws_lambda_event_source_mapping" "kinesis_to_lambda" {
  event_source_arn  = aws_kinesis_stream.kinesis_stream.arn
  function_name     = aws_lambda_function.lambda_RC.function_name
  starting_position = local.startingPosition
  depends_on        = [
    aws_iam_role_policy_attachment.kinesis_processing
  ]
}