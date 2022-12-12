data "aws_availability_zones" "available" {
  provider = aws.default
  state    = "available"
}

resource "aws_vpc" "custom_vpc" {
  provider             = aws.default
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "node_docker_tutorial"
  }
}

resource "aws_subnet" "public_a" {
  provider          = aws.default
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "public_b" {
  provider          = aws.default
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_internet_gateway" "internet_gateway" {
  provider = aws.default
  vpc_id   = aws_vpc.custom_vpc.id
}

resource "aws_route" "internet_access" {
  provider               = aws.default
  route_table_id         = aws_vpc.custom_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_security_group" "custom_security_group" {
  provider    = aws.default
  name        = "custom_security_group"
  description = "Allow TLS inbound traffic on port 80 (http)"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 80
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "custom_security_group"
  }
}