
resource "aws_subnet" "public_subnet" {
  for_each                = data.aws_availability_zones.available.names
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 4, 3 + var.az_number[each.value.name_suffix])
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.vpc_name}-public-subnet-${each.key}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.vpc_name}-internet-gateway"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${local.vpc_name}-route-table-public"
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table_association" "route_table_association_public" {
  for_each       = data.aws_availability_zones.available.names
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.route_table_public.id
}