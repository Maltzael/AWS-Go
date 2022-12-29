locals {
  #lambda locals#
  lambda1Name         = "lambda_ST"
  lambda2Name         = "lambda_RC"
  lambda3Name         = "lambda_RC_api"
  handler1            = "lambda_sender"
  handler2            = "lambda_receiver"
  handler3            = "lambda_receiver_api"
  runtime             = "go1.x"
  typeForArchive      = "zip"
  sourceDirArchive1   = "${path.module}/bin/lambda_sender"
  sourceDirArchive2   = "${path.module}/bin/lambda_receiver"
  sourceDirArchive3   = "${path.module}/bin/lambda_receiver_api"
  fileNamePathLambda1 = "${path.module}/bin/lambda_sender.zip"
  fileNamePathLambda2 = "${path.module}/bin/lambda_receiver.zip"
  fileNamePathLambda3 = "${path.module}/bin/lambda_receiver_api.zip"
  #kinesis locals#
  kinesisName         = "kinesis_stream"
  shardCount          = 1
  retentionPeriod     = 48
  shardLevelMetrics   = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]
  startingPosition = "LATEST"
  #s3 and trigger
  bucketName       = "1234bucket-for-lambda-original-name"
  bucketAcl        = "private"
  eventsTrigger    = ["s3:ObjectCreated:*"]
  statementId      = "AllowS3Invoke"
  actionInvoke     = "lambda:InvokeFunction"
  principalInvoke  = "s3.amazonaws.com"
  sourceArn        = "arn:aws:s3:::${aws_s3_bucket.bucket_lambda_data.id}"
  #api gateway
  nameApiGateway   = "API Gateway post"
  stageName        = "test"
}


### 3 lambda and 3 archives for lambda ###
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

resource "aws_lambda_function" "lambda_RC_api" {
  filename      = data.archive_file.zip_the_go_lambda3.output_path
  function_name = local.lambda3Name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = local.handler3
  runtime       = local.runtime
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
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-post.id
  parent_id   = aws_api_gateway_rest_api.api-gateway-post.root_resource_id
  path_part   = "{proxy+}"
}

### 1 api gateway ###
resource "aws_api_gateway_rest_api" "api-gateway-post" {
  name = local.nameApiGateway
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "send" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-post.id
  parent_id   = aws_api_gateway_rest_api.api-gateway-post.root_resource_id
  path_part   = "send"
}

// POST
resource "aws_api_gateway_method" "post" {
  rest_api_id      = aws_api_gateway_rest_api.api-gateway-post.id
  resource_id      = aws_api_gateway_resource.send.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "lambda-trigger" {
  rest_api_id             = aws_api_gateway_rest_api.api-gateway-post.id
  resource_id             = aws_api_gateway_resource.send.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_RC_api.invoke_arn
}

### deployment of api gateway###
resource "aws_api_gateway_deployment" "deployment1" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-post.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api-gateway-post.body))
  }

  depends_on = [aws_api_gateway_integration.lambda-trigger]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "deployment" {
  deployment_id = aws_api_gateway_deployment.deployment1.id
  rest_api_id   = aws_api_gateway_rest_api.api-gateway-post.id
  stage_name    = local.stageName
}

output "complete_invoke_url" {
  value = "${aws_api_gateway_deployment.deployment1.invoke_url}${aws_api_gateway_stage.deployment.stage_name}/${aws_api_gateway_resource.send.path_part}"
}