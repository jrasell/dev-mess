data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.1.0/24"
  instance_tenancy = "default"

  tags = {
    Name  = var.stack_name
    Owner = var.stack_owner
  }
}

resource "aws_internet_gateway" "nomad_test_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name  = var.stack_name
    Owner = var.stack_owner
  }
}

resource "aws_default_route_table" "nomad_test_route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad_test_igw.id
  }

  tags = {
    Name  = var.stack_name
    Owner = var.stack_owner
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name  = var.stack_name
    Owner = var.stack_owner
  }
}

resource "aws_security_group" "allow_all" {
  name   = "allow_all"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block,
      "${chomp(data.http.myip.response_body)}/32",
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name  = var.stack_name
    Owner = var.stack_owner
  }
}
