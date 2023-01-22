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
  vpcCidrBlock           = "10.0.0.0/16"
  projectNameForVpc      = "vpc_main"
  subnetPublicCidrBlock  = "10.0.0.0/21"
  subnetPrivateCidrBlock = "10.0.8.0/21"
  subnets_private_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
  subnets_public_ids = [for subnet in aws_subnet.public_subnet : subnet.id]

}


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

### DocumentDB deployment and vpc with subnets###
resource "aws_docdb_cluster" "docDb" {
  cluster_identifier      = local.clusterId
  engine                  = local.engineDocumentDb
  master_username         = local.userNameDocumentDb
  master_password         = local.passwordDocumentDb
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.subnet_group_docDb.name
  vpc_security_group_ids  = [aws_default_security_group.default_security_group.id]
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "docdb-cluster-demo-${count.index}"
  cluster_identifier = aws_docdb_cluster.docDb.id
  instance_class     = "db.t3.medium"
}

resource "aws_vpc" "vpc" {
  cidr_block = local.vpcCidrBlock
  tags       = {
    Name = local.projectNameForVpc
  }
}

#resource "aws_subnet" "subnet_public" {
#  vpc_id                  = aws_vpc.vpc.id
#  cidr_block              = local.subnetPublicCidrBlock
#  map_public_ip_on_launch = true
#  tags                    = {
#    Name = "${local.projectNameForVpc}-subnet-public"
#  }
#}

resource "aws_docdb_subnet_group" "subnet_group_docDb" {
  subnet_ids = local.subnets_private_ids
  tags       = {
    Name = "subnet_group_docDb"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.projectNameForVpc}-internet-gateway"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${local.projectNameForVpc}-route-table-public"
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  count                   = length(data.aws_availability_zones.available.names)
  subnet_id      = local.subnets_public_ids[count.index]
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
  tags       = {
    Name = "${local.projectNameForVpc}-eip"
  }
}
#resource "aws_nat_gateway" "nat_gateway" {
#  allocation_id = aws_eip.eip.id
#  subnet_id     = aws_subnet.subnet_public.id
#
#  tags = {
#    Name = "${local.projectNameForVpc}-nat-gateway"
#  }
#}
data "aws_availability_zones" "available" {

}

resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${10+count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = {
    Name = "PublicSubnet"
  }
}
resource "aws_subnet" "private_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${20+count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags                    = {
    Name = "PrivateSubnet"
  }
}
#resource "aws_route_table" "route_table_private" {
#  vpc_id = aws_vpc.vpc.id
#
#  route {
#    cidr_block     = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.nat_gateway.id
#  }
#
#  tags = {
#    Name = "${local.projectNameForVpc}-route-table-private"
#  }
#}

#resource "aws_route_table_association" "route_table_association_private" {
#  subnet_id      = aws_subnet.subnet_private.id
#  route_table_id = aws_route_table.route_table_private.id
#}

#
#resource "aws_default_network_acl" "default_network_acl" {
#  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
#  subnet_ids             = merge(local.subnets_private_ids, local.subnets_public_ids)
#  ingress {
#    protocol   = -1
#    rule_no    = 100
#    action     = "allow"
#    cidr_block = "0.0.0.0/0"
#    from_port  = 0
#    to_port    = 0
#  }
#
#  egress {
#    protocol   = -1
#    rule_no    = 100
#    action     = "allow"
#    cidr_block = "0.0.0.0/0"
#    from_port  = 0
#    to_port    = 0
#  }
#
#  tags = {
#    Name = "${local.projectNameForVpc}-default-network-acl"
#  }
#}
resource "aws_default_security_group" "default_security_group" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["127.0.0.1/32"]
  }

  tags = {
    Name = "${local.projectNameForVpc}-default-security-group"
  }
}
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}