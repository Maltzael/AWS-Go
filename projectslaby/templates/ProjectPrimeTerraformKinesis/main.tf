locals {
  ###### lambdas variables #######
  fileNamePathLambda1 = "${path.module}/python/lambdaReciver.zip"
  fileNamePathLambda2 = "${path.module}/python/lambdaEvent.zip"
  lambda1Name         = "lambdaReceiver"
  lambda1Description  = ""
  lambda1Size         = ""
  lambda1Trace        = true
  lambda2Name         = "lambdaEvent"
  handler1            = "lambdaReceiver.lambdaReceiver"
  handler2            = "lambdaEvent.lambdaEvent"
  runtime             = "python3.9"
  typeForArchive      = "zip"
  sourceDirArchive    = "${path.module}/python/"
  SFTPhost            = ""
  SFTPuser            = ""
  SFTPpass            = ""


  ##### kinesis variables #####
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

  ##### invoke variables #####
  actionInvoke              = "lambda:InvokeFunction"
  invokeName                = "InvokeEvery5Minutes"
  scheduleExpression        = "rate(5 minutes)"
  principalInvokePermission = "events.amazonaws.com"
  statementId               = "AllowLambdaInvoke"
  statementIdPermission     = "AllowExecutionFromCloudWatch"
  principalInvoke           = "s3.amazonaws.com"

}

########################### 2 lambdas  and 2 archives ###############################
resource "aws_lambda_function" "lambdaReceiver" {
  filename      = local.fileNamePathLambda1
  function_name = local.lambda1Name
  role          = aws_iam_role.iamRole.arn
  handler       = local.handler1
  runtime       = local.runtime

}

module detailedvendorledgerentry_vn_lambda {
  source = "git@github.com:xiatechs/sdv-terraform-aws-lambda.git?ref=v1"

  //stack_name                                     = local.stackName // nazwa klocka
  lambda_function_name                           = local.lambda1Name
  //lambda_function_handler                        = local.dynamoReceiverLambdaVN // zastanowic sie co z tym zrobic
  lambda_function_memory_size                    = local.lambda1Size
  lambda_function_name_prefix                    = ""
  lambda_function_description                    = local.lambda1Description
  lambda_function_enabled                        = true
  lambda_function_alarms_enabled                 = true
  lambda_function_enable_vpc_config              = true
  lambda_function_reserved_concurrent_executions = -1
  lambda_function_vpc_config                     = var.lambda_function_vpc_config
  lambda_function_kms_key_arn                    = var.lambda_function_kms_key_arn
  lambda_function_sns_topic_monitoring_arn       = var.lambda_function_sns_topic_monitoring_arn
  lambda_function_source_base_path               = var.lambda_function_source_base_path
  lambda_function_env_vars                       = merge(var.lambda_function_env_vars, {
    TRACE : local.lambda1Trace,
    SFTP_HOST : local.SFTPhost,
    SFTP_USER : local.SFTPuser,
    SFTP : local.SFTPpass,

    //TARGET_STREAM : "${local.kinesisStreamName}",    //bardzo potrzebne
    SWALLOW_EVENTS : ""
  })
  lambda_function_existing_execute_role = var.lambda_function_existing_execute_role
  account_id                            = local.account_id
  client                                = local.client
  environment                           = local.environment
  region                                = local.region
}

resource "aws_lambda_function" "lambdaEvent" {
  filename      = local.fileNamePathLambda2
  function_name = local.lambda2Name
  role          = aws_iam_role.iamRole.arn
  handler       = local.handler2
  runtime       = local.runtime
}

data "archive_file" "zip_the_python_lambda1" {
  type        = local.typeForArchive
  source_dir  = local.sourceDirArchive
  output_path = local.fileNamePathLambda1
}

data "archive_file" "zip_the_python_lambda2" {
  type        = local.typeForArchive
  source_dir  = local.sourceDirArchive
  output_path = local.fileNamePathLambda2
}

###### 1 kinesis #######
resource "aws_kinesis_stream" "kinesis_stream" {
  name                = local.kinesisName
  shard_count         = local.shardCount
  retention_period    = local.retentionPeriod
  shard_level_metrics = local.shardLevelMetrics
}

##### invoke and permissions ######

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = local.invokeName
  schedule_expression = local.scheduleExpression
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = local.statementIdPermission
  action        = local.actionInvoke
  function_name = aws_lambda_function.lambdaReceiver.function_name
  principal     = local.principalInvokePermission
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}

resource "aws_lambda_permission" "allow_cloudwatch2" {
  statement_id  = local.statementIdPermission
  action        = local.actionInvoke
  function_name = aws_lambda_function.lambdaEvent.function_name
  principal     = local.principalInvokePermission
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}

resource "aws_cloudwatch_event_target" "invoke_lambda1_5_min" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = local.lambda1Name
  arn       = aws_lambda_function.lambdaReceiver.arn
}

resource "aws_cloudwatch_event_target" "invoke_lambda2_5_min" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = local.lambda2Name
  arn       = aws_lambda_function.lambdaEvent.arn
}