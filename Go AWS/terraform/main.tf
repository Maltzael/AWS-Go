locals {
  #lambda locals#
  lambda1Name         = "lambda_receiver_from_s3"
  lambda2Name         = "lambda_receiver_from_kinesis"
  lambda3Name         = "lambda_receiver_auth"
  lambda4Name         = "lambda_receiver_from_api"
  handler1            = "lambda_receiver_from_s3"
  handler2            = "lambda_receiver_from_kinesis"
  handler3            = "lambda_receiver_auth"
  handler4            = "lambda_receiver_from_api"
  runtime             = "go1.x"
  typeForArchive      = "zip"
  sourceDirArchive1   = "${path.module}/bin/lambda_receiver_from_s3"
  sourceDirArchive2   = "${path.module}/bin/lambda_receiver_from_kinesis"
  sourceDirArchive3   = "${path.module}/bin/lambda_receiver_auth"
  sourceDirArchive4   = "${path.module}/bin/lambda_receiver_from_api"
  fileNamePathLambda1 = "${path.module}/bin/lambda_receiver_from_s3.zip"
  fileNamePathLambda2 = "${path.module}/bin/lambda_receiver_from_kinesis.zip"
  fileNamePathLambda3 = "${path.module}/bin/lambda_receiver_auth.zip"
  fileNamePathLambda4 = "${path.module}/bin/lambda_receiver_from_api.zip"
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

  startingPosition       = "LATEST"
  #s3 and trigger
  bucketName             = "1234bucket-for-lambda-original-name"
  bucketAcl              = "private"
  eventsTrigger          = ["s3:ObjectCreated:*"]
  statementId            = "AllowS3Invoke"
  actionInvoke           = "lambda:InvokeFunction"
  principalInvoke        = "s3.amazonaws.com"
  sourceArn              = "arn:aws:s3:::${aws_s3_bucket.bucket_lambda_data.id}"
  #api gateway
  nameApiGateway         = "API Gateway post"
  stageName              = "test"
  #documentDb
  //change for var later\
  clusterId              = "my-docdb-cluster"
  engineDocumentDb       = "docdb"
  userNameDocumentDb     = "someusername"
  passwordDocumentDb     = "somepassword123"


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

### 1 api gateway and 2 endpoints with triggers ###
resource "aws_api_gateway_rest_api" "api-gateway-post" {
  name = local.nameApiGateway
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-post.id
  parent_id   = aws_api_gateway_rest_api.api-gateway-post.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "receiver" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-post.id
  parent_id   = aws_api_gateway_rest_api.api-gateway-post.root_resource_id
  path_part   = "rec"
}

// POST
resource "aws_api_gateway_method" "post_auth" {
  rest_api_id      = aws_api_gateway_rest_api.api-gateway-post.id
  resource_id      = aws_api_gateway_resource.auth.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}
resource "aws_api_gateway_method" "post_api" {
  rest_api_id      = aws_api_gateway_rest_api.api-gateway-post.id
  resource_id      = aws_api_gateway_resource.receiver.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "lambda-trigger_auth" {
  rest_api_id             = aws_api_gateway_rest_api.api-gateway-post.id
  resource_id             = aws_api_gateway_resource.auth.id
  http_method             = aws_api_gateway_method.post_auth.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_RC_auth.invoke_arn
}

resource "aws_api_gateway_integration" "lambda-trigger_receiver" {
  rest_api_id             = aws_api_gateway_rest_api.api-gateway-post.id
  resource_id             = aws_api_gateway_resource.receiver.id
  http_method             = aws_api_gateway_method.post_api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_RC_from_api.invoke_arn
}

### deployment of api gateway###
resource "aws_api_gateway_deployment" "deployment1" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-post.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api-gateway-post.body))
  }

  depends_on = [aws_api_gateway_integration.lambda-trigger_auth, aws_api_gateway_integration.lambda-trigger_receiver]
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
  value = "${aws_api_gateway_deployment.deployment1.invoke_url}${aws_api_gateway_stage.deployment.stage_name}/${aws_api_gateway_resource.auth.path_part}\n${aws_api_gateway_deployment.deployment1.invoke_url}${aws_api_gateway_stage.deployment.stage_name}/${aws_api_gateway_resource.receiver.path_part}"

}
