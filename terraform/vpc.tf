resource "aws_vpc" "goalert" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "goalert-${var.env}" })
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.goalert.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.region}a"

  tags = merge(local.common_tags, { Name = "goalert-public-a-${var.env}" })
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.goalert.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}b"

  tags = merge(local.common_tags, { Name = "goalert-public-b-${var.env}" })
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.goalert.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}a"

  tags = merge(local.common_tags, { Name = "goalert-private-a-${var.env}" })
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.goalert.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}b"

  tags = merge(local.common_tags, { Name = "goalert-private-b-${var.env}" })
}

resource "aws_internet_gateway" "goalert" {
  vpc_id = aws_vpc.goalert.id

  tags = merge(local.common_tags, { Name = "goalert-igw-${var.env}" })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, { Name = "goalert-nat-eip-${var.env}" })
}

resource "aws_nat_gateway" "goalert" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = merge(local.common_tags, { Name = "goalert-nat-${var.env}" })

  depends_on = [aws_internet_gateway.goalert]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.goalert.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.goalert.id
  }

  tags = merge(local.common_tags, { Name = "goalert-public-rt-${var.env}" })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.goalert.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.goalert.id
  }

  tags = merge(local.common_tags, { Name = "goalert-private-rt-${var.env}" })
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

