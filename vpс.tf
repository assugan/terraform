provider "aws" {}


resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "Project_VPC"
 }
}


resource "aws_subnet" "pub_subnets" {
 count      = length(var.pub_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.pub_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "PubSubnet ${count.index + 1}"
 }
}


resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "PrivatSubnet ${count.index + 1}"
 }
}


resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "Project_VPC_IG"
 }
}

resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id
 }
 
 tags = {
   Name = "2nd_Route_Table"
 }
}

resource "aws_route_table_association" "pub_subnet_asso" {
 count = length(var.pub_subnet_cidrs)
 subnet_id      = element(aws_subnet.pub_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}


resource "aws_eip" "elip" {
  count = length(var.private_subnet_cidrs)
  vpc   = true
  tags = {
    Name = "${var.env}-nat-gw-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "ngw" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)
  tags = {
    Name = "${var.env}-nat-gw-${count.index + 1}"
  }
}