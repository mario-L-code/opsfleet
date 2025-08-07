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

resource "aws_route_table" "opsfleet_rt" {
  vpc_id = aws_vpc.opsfleet_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.opsfleet_igw.id
  }

  tags = {
    Name = "opsfleet_rt"
  }
}

resource "aws_subnet" "pub_sub_1" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "opsfleet_pub_sub_1"
  }
}

resource "aws_subnet" "pub_sub_2" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "opsfleet_pub_sub_2"
  }
}

resource "aws_subnet" "priv_sub_1" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.16.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "opsfleet_priv_sub_1"
  }
}

resource "aws_subnet" "priv_sub_2" {
  vpc_id            = aws_vpc.opsfleet_vpc.id
  cidr_block        = "172.20.17.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "opsfleet_priv_sub_2"
  }
}

resource "aws_route_table_association" "pub_sub_1" {
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.opsfleet_rt.id
}

resource "aws_route_table_association" "pub_sub_2" {
  subnet_id      = aws_subnet.pub_sub_2.id
  route_table_id = aws_route_table.opsfleet_rt.id
}
