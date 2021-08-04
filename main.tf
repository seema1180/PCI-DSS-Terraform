
# Configure the AWS Provider
terraform {
  required_providers {
    aws       = {
      source  = "hashicorp/aws"
      version = "3.52.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

#create Management VPC

resource "aws_vpc" "main" {
  cidr_block    = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "management"
  }
}
#create Availability zone

data "aws_availability_zones" "azone1" {
  state = "available"
}
 #create subnet1

resource "aws_subnet" "man_public-subnet-1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-west-2a"
}  

resource "aws_internet_gateway" "net" {
  vpc_id = aws_vpc.main.id
}
resource "aws_eip" "nat_gateway" {
  vpc  = true
  depends_on = [aws_internet_gateway.net]
}

#create gateway1
resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.man_public-subnet-1.id
  depends_on = [aws_internet_gateway.net]
}

resource "aws_security_group" "securitygroup1" {
  name        = "securitygroup1"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  #private subnet for zone1
}
resource "aws_subnet" "man_private-subnet1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone  = "us-west-2a"
  map_public_ip_on_launch = false
}

#create availabilty zone2
data "aws_availability_zones" "azone2" {
  state = "available"
}
resource "aws_subnet" "man_public-subnet-2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-west-2a"
}  
resource "aws_subnet" "man_private-subnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.50.0/24"
  availability_zone  = "us-west-2a"
  map_public_ip_on_launch = false
}


###### Create production vpc
resource "aws_vpc" "prod" {
  cidr_block    = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "production"
  }
}
#create Availability zone1

data "aws_availability_zones" "azone_prod1" {
  state = "available"
}
 #create subnet1

resource "aws_subnet" "public-subnet-prod1" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "192.168.0.0/17"
  map_public_ip_on_launch = "true"
  availability_zone = "us-west-2b"
}  
resource "aws_eip" "nat_gateway_prod" {
  vpc  = true
  depends_on = [aws_internet_gateway.net]
}

#create gateway1
resource "aws_nat_gateway" "NAT_prod" {
  allocation_id = aws_eip.nat_gateway_prod.id
  subnet_id = aws_subnet.public-subnet-prod1.id
  depends_on = [aws_internet_gateway.net]
}
resource "aws_subnet" "private-subnet_prod1" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "192.168.128.0/18"
  availability_zone  = "us-west-2b"
  map_public_ip_on_launch = false
}
resource "aws_subnet" "private-subnet_prod2" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "192.168.192.0/19"
  availability_zone  = "us-west-2b"
  map_public_ip_on_launch = false
}
#create Availability zone2_prod

data "aws_availability_zones" "azone_prod2" {
  state = "available"
}

resource "aws_subnet" "public-subnet-prod2" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "192.168.224.0/20"
  map_public_ip_on_launch = "true"
  availability_zone = "us-west-2b"
}  
resource "aws_internet_gateway" "net_prod2" {
  vpc_id = aws_vpc.prod.id
}
resource "aws_eip" "nat_gateway_prod2" {
  vpc  = true
  depends_on = [aws_internet_gateway.net_prod2]
}

#create gateway2_prod
resource "aws_nat_gateway" "NAT_prod2" {
  allocation_id = aws_eip.nat_gateway_prod2.id
  subnet_id = aws_subnet.public-subnet-prod2.id
  depends_on = [aws_internet_gateway.net_prod2]
}
resource "aws_subnet" "private-subnet_prod_1" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "192.168.240.0/21"
  availability_zone  = "us-west-2b"
  map_public_ip_on_launch = false
}
resource "aws_subnet" "private-subnet_prod_2" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "192.168.248.0/22"
  availability_zone  = "us-west-2b"
  map_public_ip_on_launch = false
}
# VPC Peering
###############################################################################
resource "aws_vpc_peering_connection" "PeeringConnectionProduction" {
  peer_vpc_id = aws_vpc.prod.id
  vpc_id      = aws_vpc.main.id
  auto_accept = true

  tags = {
    Name        = "vpc-peer-production-management"
  }
}