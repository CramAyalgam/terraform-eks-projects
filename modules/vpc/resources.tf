resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = {
    Name: "${var.prefix_tag_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name: "${var.prefix_tag_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name: "${var.prefix_tag_name}-public"
  }
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  availability_zone = "${var.region}${each.key}"
  cidr_block = each.value
  vpc_id = aws_vpc.main.id

  map_public_ip_on_launch = true

  tags = {
    Name: "${var.prefix_tag_name}-public-${each.key}"
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "public" {
  for_each = var.public_subnets
  
  tags = {
    Name: "${var.prefix_tag_name}-elastic-ip"
  }
}

# Multiple Nat gateways
resource "aws_nat_gateway" "public" {

  allocation_id = aws_eip.public["a"].id
  subnet_id = aws_subnet.public["a"].id

  tags = {
    Name: "${var.prefix_tag_name}-nat-a"
  }
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.main.id

  tags = {
    Name: "${var.prefix_tag_name}-private-${each.key}"
  }
}

resource "aws_route" "private_nat" {
  for_each = var.private_subnets

  route_table_id = aws_route_table.private[each.key].id
  nat_gateway_id = aws_nat_gateway.public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  availability_zone = "${var.region}${each.key}"
  cidr_block = each.value
  vpc_id = aws_vpc.main.id

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix_tag_name}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
  
}

resource "aws_security_group" "base" {
  name = "base"
  description = "Base security group that allows internal traffic"

  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    protocol  = "tcp"
    to_port   = 0
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
  }

}

resource "aws_route_table" "rds" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name: "${var.prefix_tag_name}-rds"
  }
}

resource "aws_route_table_association" "rds" {
  for_each = var.rds_subnets

  subnet_id = aws_subnet.rds[each.key].id
  route_table_id = aws_route_table.rds.id
}

resource "aws_subnet" "rds" {
  for_each = var.rds_subnets

  availability_zone = "${var.region}${each.key}"
  cidr_block = each.value
  vpc_id = aws_vpc.main.id

  map_public_ip_on_launch = false

  tags = {
    Name: "${var.prefix_tag_name}-rds-${each.key}"
  }
}
