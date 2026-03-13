# Transit Gateway Attachment
# Attaches VPC to Transit Gateway for inter-account connectivity
# Requirements: 4.3

# Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  count = var.enable_transit_gateway && var.transit_gateway_id != "" ? 1 : 0

  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.main.id
  subnet_ids         = aws_subnet.private[*].id

  # Enable DNS support for Transit Gateway
  dns_support = "enable"

  # Enable IPv6 support if needed
  ipv6_support = "disable"

  # Appliance mode for network appliances (disabled by default)
  appliance_mode_support = "disable"

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-tgw-attachment"
    }
  )
}

# Add routes to Transit Gateway in private route tables
resource "aws_route" "private_to_tgw" {
  count = var.enable_transit_gateway && var.transit_gateway_id != "" ? var.availability_zones : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "10.0.0.0/8" # Route RFC1918 private networks to TGW
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
}

# Add routes to Transit Gateway in isolated route tables
resource "aws_route" "isolated_to_tgw" {
  count = var.enable_transit_gateway && var.transit_gateway_id != "" ? 1 : 0

  route_table_id         = aws_route_table.isolated.id
  destination_cidr_block = "10.0.0.0/8" # Route RFC1918 private networks to TGW
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
}
