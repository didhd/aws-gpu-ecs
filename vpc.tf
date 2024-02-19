data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecs-vpc"
  }
}

# Calculate the CIDR blocks for public subnets
locals {
  public_subnet_cidrs  = [for i in range(length(data.aws_availability_zones.available.names)) : cidrsubnet(aws_vpc.ecs_vpc.cidr_block, 4, i)]
  private_subnet_cidrs = [for i in range(length(data.aws_availability_zones.available.names)) : cidrsubnet(aws_vpc.ecs_vpc.cidr_block, 4, i + length(data.aws_availability_zones.available.names))]
}

# Create public subnets
resource "aws_subnet" "public_subnet" {
  count                   = length(local.public_subnet_cidrs)
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = element(local.public_subnet_cidrs, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Create private subnets
resource "aws_subnet" "private_subnet" {
  count             = length(local.private_subnet_cidrs)
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = element(local.private_subnet_cidrs, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "ecs-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = length(aws_subnet.public_subnet.*.id)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip" {}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = {
    Name = "ecs-nat-gw"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_rta" {
  count          = length(aws_subnet.private_subnet.*.id)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.ecs_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-sg"
  }
}
