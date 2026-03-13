# VPC Resources
# Creates VPC with subnets across availability zones
# Requirements: 4.2, 4.4

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Calculate subnet CIDRs if not provided
locals {
  # Get the first N availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones)

  # Calculate subnet CIDRs if not explicitly provided
  vpc_cidr_parts    = split("/", var.vpc_cidr)
  vpc_prefix_length = tonumber(vpc_cidr_parts[1])
  subnet_newbits    = 8 - (vpc_prefix_length - 16) # Typically /24 subnets from /16 VPC

  # Generate subnet CIDRs for each tier if not provided
  public_subnets = length(var.subnet_configuration.public_subnets) > 0 ? var.subnet_configuration.public_subnets : [
    for i in range(var.availability_zones) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i)
  ]

  private_subnets = length(var.subnet_configuration.private_subnets) > 0 ? var.subnet_configuration.private_subnets : [
    for i in range(var.availability_zones) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i + var.availability_zones)
  ]

  isolated_subnets = length(var.subnet_configuration.isolated_subnets) > 0 ? var.subnet_configuration.isolated_subnets : [
    for i in range(var.availability_zones) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i + (2 * var.availability_zones))
  ]
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.availability_zones

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-public-${local.azs[count.index]}"
      Tier = "Public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.availability_zones

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-private-${local.azs[count.index]}"
      Tier = "Private"
    }
  )
}

# Isolated Subnets
resource "aws_subnet" "isolated" {
  count = var.availability_zones

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.isolated_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-isolated-${local.azs[count.index]}"
      Tier = "Isolated"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.availability_zones

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-nat-eip-${local.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways (one per AZ for high availability)
resource "aws_nat_gateway" "main" {
  count = var.availability_zones

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-nat-${local.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-public-rt"
      Tier = "Public"
    }
  )
}

# Public Route to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.availability_zones

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for NAT Gateway routing)
resource "aws_route_table" "private" {
  count = var.availability_zones

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-private-rt-${local.azs[count.index]}"
      Tier = "Private"
    }
  )
}

# Private Routes to NAT Gateways
resource "aws_route" "private_nat" {
  count = var.availability_zones

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.availability_zones

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Isolated Route Table (no internet access)
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-isolated-rt"
      Tier = "Isolated"
    }
  )
}

# Isolated Subnet Route Table Associations
resource "aws_route_table_association" "isolated" {
  count = var.availability_zones

  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}
