resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "bountyhunter-public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/25"

  depends_on = [ aws_vpc.main ]
}

resource "aws_subnet" "bountyhunter-private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.128/25"

  depends_on = [ aws_vpc.main ]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  depends_on = [ aws_vpc.main ]
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.bountyhunter-public.id

  depends_on = [ aws_eip.nat_eip, aws_subnet.bountyhunter-public ]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  depends_on = [ aws_nat_gateway.nat ]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.bountyhunter-private.id
  route_table_id = aws_route_table.private_rt.id

  depends_on = [ aws_subnet.bountyhunter-private, aws_route_table.private_rt ]
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.bountyhunter-public.id
  route_table_id = aws_route_table.public_rt.id

  depends_on = [ aws_subnet.bountyhunter-public, aws_route_table.public_rt ]
}