resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    tags = {
        Name = "${var.environment}"
    } 
}

resource "aws_subnet" "public_subnet" {
    count = length(var.public_subnets)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnets[count.index]
    map_public_ip_on_launch = true
    availability_zone = var.public_azs[count.index]

    tags = {
        Name = "${var.environment}-public-${count.index}"
        "kubernetes.io/role/elb"          = "1"   # on public subnets
        "kubernetes.io/role/internal-elb" = "1"   # on private subnets
        "kubernetes.io/cluster/${var.environment}-cluster" = "shared"
    }
}

resource "aws_subnet" "private_subnet" {
    count = length(var.private_subnets)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnets[count.index]
    map_public_ip_on_launch = false
    availability_zone = var.private_azs[count.index]

    tags = {
        Name = "${var.environment}-private-${count.index}"
        "kubernetes.io/role/elb"          = "1"   # on public subnets
        "kubernetes.io/role/internal-elb" = "1"   # on private subnets
        "kubernetes.io/cluster/${var.environment}-cluster" = "shared"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "${var.environment}-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}