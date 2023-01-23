resource "aws_subnet" "private_subnet" {
  for_each                = data.aws_availability_zones.available.names
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 4, var.az_number[each.value])
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.vpc_name}-private-subnet-${each.key}"
  }
}

resource "aws_eip" "nat_gateway_eip" {
  for_each = data.aws_availability_zones.available.names
  vpc      = true
  tags = {
    Name = "${local.vpc_name}-nat-gateway-eip-${each.key}"
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway" {
  for_each      = data.aws_availability_zones.available.names
  allocation_id = aws_eip.nat_gateway_eip[each.key].id
  subnet_id     = aws_subnet.public_subnet[each.key].id
  tags = {
    Name = "${local.vpc_name}-nat-gateway-${each.key}"
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "route_table_private" {
  for_each = data.aws_availability_zones.available.names
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[each.key].id
  }
  tags = {
    Name = "${local.vpc_name}-route-table-public-${each.key}"
  }
  depends_on = [aws_nat_gateway.nat_gateway]
}

resource "aws_route_table_association" "route_table_association_private" {
  for_each       = data.aws_availability_zones.available.names
  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.route_table_private[each.key].id
}
