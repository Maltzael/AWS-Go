locals {
  vpc_cidr_block = "10.0.0.0/16"
  vpc_name       = "main-vpc"
  #   subnet_publicidrBlock  = "10.0.0.0/21"
  #   subnetPrivateCidrBlock = "10.0.8.0/21"
}

variable "az_number" {
  # Assign a number to each AZ letter used in our configuration
  default = {
    "eu-west-1a" = 1
    "eu-west-1b" = 2
    "eu-west-1c" = 3
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# data "aws_availability_zones" "all" {
#   for_each = aws_avaiability_zones.available.names
#   name     = each.key
#   depends_on = [data.aws_availability_zones.available]
# }

resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr_block
  tags = {
    Name = local.vpc_name
  }
}

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
  }

  tags = {
    Name = "${local.vpc_name}-default-security-group"
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
    Name = "${local.vpc_name}-allow_tls"
  }
}
