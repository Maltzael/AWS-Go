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
  #s3 and trigger
  bucketName    = "1234bucket-for-lambda-original-name"
  bucketAcl     = "private"
  eventsTrigger = ["s3:ObjectCreated:*"]
  statementId               = "AllowS3Invoke"
  actionInvoke              = "lambda:InvokeFunction"
  principalInvoke           = "s3.amazonaws.com"
  sourceArn                 = "arn:aws:s3:::${aws_s3_bucket.bucket_lambda_data.id}"

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

### 1 s3 and trigger to lambda ###
resource "aws_s3_bucket" "bucket_lambda_data" {
  bucket = local.bucketName
}

resource "aws_s3_bucket_acl" "acl_bucket" {
  bucket = aws_s3_bucket.bucket_lambda_data.id
  acl    = local.bucketAcl
}

resource "aws_s3_bucket_notification" "aws-s3-lambda-trigger" {
  bucket = aws_s3_bucket.bucket_lambda_data.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_ST.arn
    events              = local.eventsTrigger

  }
}
resource "aws_lambda_permission" "permission_s3_trigger" {
  statement_id  = local.statementId
  action        = local.actionInvoke
  function_name = aws_lambda_function.lambda_ST.function_name
  principal     = local.principalInvoke
  source_arn    = local.sourceArn
}
