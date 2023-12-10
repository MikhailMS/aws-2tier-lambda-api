####
## Terraform providers
###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = var.bucket
    key    = var.key
    region = var.region
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-2"
  profile = "default"
}
####


####
## Configure Network level infrastructure
###
# Create a VPC
resource "aws_vpc" "main_network" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Main Network"
  }
}


##
# Create all required subnets
resource "aws_subnet" "subnets" {
  for_each = {
    for k, v in local.subnets_array : "${v.name}" => v
  }

  vpc_id                  = aws_vpc.main_network.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.tag_name
  }

  depends_on = [aws_vpc.main_network]
}
##


##
# Resolve Public Subnets
#
# Create and link Internet Gateway
resource "aws_internet_gateway" "int_gateway" {
  count = length([ for key, _ in aws_subnet.subnets : key if length(regexall("^subnet*", key)) > 0 ]) > 0 ? 1 : 0

  tags = {
    Name = "Main Internet Gateway"
  }
}

resource "aws_internet_gateway_attachment" "int_gateway_attach" {
  count = length([ for key, _ in aws_subnet.subnets : key if length(regexall("^subnet*", key)) > 0 ]) > 0 ? 1 : 0

  vpc_id              = aws_vpc.main_network.id
  internet_gateway_id = aws_internet_gateway.int_gateway[0].id

  depends_on = [aws_vpc.main_network, aws_internet_gateway.int_gateway]
}


# Create and resolve Public Route Table
resource "aws_route_table" "route_table" {
  count = length([ for key, _ in aws_subnet.subnets : key if length(regexall("^subnet*", key)) > 0 ]) > 0 ? 1 : 0

  vpc_id = aws_vpc.main_network.id

  # Route for public access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.int_gateway[0].id
  }

  tags = {
    Name = "Public Route Table"
  }

  depends_on = [aws_vpc.main_network, aws_internet_gateway.int_gateway]
}

resource "aws_route_table_association" "subnet_routes" {
  for_each = {
    for key, sub in aws_subnet.subnets : key => sub
    if length(regexall("^subnet*", key)) > 0
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_table[0].id

  depends_on = [aws_route_table.route_table]
}
##


##
# Resolve Private Subnets
#
# Create NAT
resource "aws_eip" "nat_eip" {
  count = length([ for key, _ in aws_subnet.subnets : key if length(regexall("^private*", key)) > 0 ]) > 0 ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = length([ for key, _ in aws_subnet.subnets : key if length(regexall("^private*", key)) > 0 ]) > 0 ? 1 : 0

  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = [for key, sub in aws_subnet.subnets: sub.id if length(regexall("^subnet*", key)) > 0][0]

  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.int_gateway]
}


# Create and resolve Private Route Table
resource "aws_route_table" "private_route_table" {
  count = length([ for key, _ in aws_subnet.subnets : key if length(regexall("^private*", key)) > 0 ]) > 0 ? 1 : 0

  vpc_id = aws_vpc.main_network.id

  # Route for public access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway[0].id
  }

  tags = {
    Name = "Private Route Table"
  }

  depends_on = [aws_vpc.main_network, aws_nat_gateway.nat_gateway]
}

resource "aws_route_table_association" "private_subnet_routes" {
  for_each = {
    for key, sub in aws_subnet.subnets : key => sub
    if length(regexall("^private*", key)) > 0
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table[0].id

  depends_on = [aws_route_table.private_route_table]
}
##
#####
