resource "aws_vpc" "opsfleet_vpc" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                     = "opsfleet_vpc"
    "kubernetes.io/cluster/opsfleet-cluster" = "owned"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "opsfleet_igw" {
  vpc_id = aws_vpc.opsfleet_vpc.id

  tags = {
    Name = "opsfleet_igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.opsfleet_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.opsfleet_igw.id
  }

  tags = {
    Name = "opsfleet_public_rt"
  }
}

# Public Subnets
resource "aws_subnet" "pub_sub_1" {
  vpc_id                  = aws_vpc.opsfleet_vpc.id
  cidr_block              = "172.20.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "opsfleet_pub_sub_1"
    "kubernetes.io/cluster/opsfleet-cluster" = "shared"
    "karpenter.sh/discovery" = "opsfleet-cluster"
  }
}

resource "aws_subnet" "pub_sub_2" {
  vpc_id                  = aws_vpc.opsfleet_vpc.id
  cidr_block              = "172.20.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "opsfleet_pub_sub_2"
    "kubernetes.io/cluster/opsfleet-cluster" = "shared"
    "karpenter.sh/discovery" = "opsfleet-cluster"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "pub_sub_1" {
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_sub_2" {
  subnet_id      = aws_subnet.pub_sub_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"

  tags = {
    Name = "opsfleet_nat_eip_1"
  }
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"

  tags = {
    Name = "opsfleet_nat_eip_2"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.pub_sub_1.id

  tags = {
    Name = "opsfleet_nat_gw_1"
  }

  depends_on = [aws_internet_gateway.opsfleet_igw]
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.pub_sub_2.id

  tags = {
    Name = "opsfleet_nat_gw_2"
  }

  depends_on = [aws_internet_gateway.opsfleet_igw]
}

# Private Subnets
resource "aws_subnet" "priv_sub_1" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.16.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name                     = "opsfleet_priv_sub_1"
    "kubernetes.io/cluster/opsfleet-cluster" = "shared"
    "karpenter.sh/discovery" = "opsfleet-cluster"
  }
}

resource "aws_subnet" "priv_sub_2" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.17.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name                     = "opsfleet_priv_sub_2"
    "kubernetes.io/cluster/opsfleet-cluster" = "shared"
    "karpenter.sh/discovery" = "opsfleet-cluster"
  }
}

# Private Route Tables
resource "aws_route_table" "priv_rt_1" {
  vpc_id = aws_vpc.opsfleet_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name = "opsfleet_private_rt_1"
  }

  depends_on = [aws_nat_gateway.nat_1]
}

resource "aws_route_table" "priv_rt_2" {
  vpc_id = aws_vpc.opsfleet_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = {
    Name = "opsfleet_private_rt_2"
  }

  depends_on = [aws_nat_gateway.nat_2]
}

# Private Route Table Associations
resource "aws_route_table_association" "priv_sub_1" {
  subnet_id      = aws_subnet.priv_sub_1.id
  route_table_id = aws_route_table.priv_rt_1.id
}

resource "aws_route_table_association" "priv_sub_2" {
  subnet_id      = aws_subnet.priv_sub_2.id
  route_table_id = aws_route_table.priv_rt_2.id
}