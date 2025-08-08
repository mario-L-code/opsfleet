resource "aws_vpc" "opsfleet_vpc" {
  cidr_block = "172.20.0.0/16"

  tags = {
    Name = "opsfleet_vpc"
  }
}

resource "aws_internet_gateway" "opsfleet_igw" {
  vpc_id = aws_vpc.opsfleet_vpc.id

  tags = {
    Name = "opsfleet_igw"
  }
}

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

resource "aws_subnet" "pub_sub_1" {
  vpc_id                  = aws_vpc.opsfleet_vpc.id
  cidr_block              = "172.20.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "opsfleet_pub_sub_1"
  }
}

resource "aws_subnet" "pub_sub_2" {
  vpc_id                  = aws_vpc.opsfleet_vpc.id
  cidr_block              = "172.20.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "opsfleet_pub_sub_2"
  }
}

resource "aws_route_table_association" "pub_sub_1" {
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_sub_2" {
  subnet_id      = aws_subnet.pub_sub_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IPs for NAT gateways
resource "aws_eip" "nat_eip_1" {
  vpc = true
}

resource "aws_eip" "nat_eip_2" {
  vpc = true
}

# NAT Gateways in each AZ
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.pub_sub_1.id

  tags = {
    Name = "nat_gw_1"
  }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.pub_sub_2.id

  tags = {
    Name = "nat_gw_2"
  }
}

# Private subnets with Karpenter discovery tag
resource "aws_subnet" "priv_sub_1" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.16.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name                     = "opsfleet_priv_sub_1"
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_subnet" "priv_sub_2" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.17.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name                     = "opsfleet_priv_sub_2"
    "karpenter.sh/discovery" = var.cluster_name
  }
}

# Private route tables for each AZ
resource "aws_route_table" "priv_rt_1" {
  vpc_id = aws_vpc.opsfleet_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name = "opsfleet_private_rt_1"
  }
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
}

# Associate private subnets with their route tables
resource "aws_route_table_association" "priv_sub_1" {
  subnet_id      = aws_subnet.priv_sub_1.id
  route_table_id = aws_route_table.priv_rt_1.id
}

resource "aws_route_table_association" "priv_sub_2" {
  subnet_id      = aws_subnet.priv_sub_2.id
  route_table_id = aws_route_table.priv_rt_2.id
}