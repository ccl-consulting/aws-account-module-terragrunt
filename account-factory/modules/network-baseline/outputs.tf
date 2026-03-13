# Network Baseline Module Outputs
# Implementation: Task 6

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the created VPC"
  value       = aws_vpc.main.arn
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "isolated_subnet_ids" {
  description = "IDs of isolated subnets"
  value       = aws_subnet.isolated[*].id
}

output "isolated_subnet_cidrs" {
  description = "CIDR blocks of isolated subnets"
  value       = aws_subnet.isolated[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "isolated_route_table_id" {
  description = "ID of the isolated route table"
  value       = aws_route_table.isolated.id
}

output "transit_gateway_attachment_id" {
  description = "ID of the Transit Gateway attachment"
  value       = var.enable_transit_gateway && var.transit_gateway_id != "" ? aws_ec2_transit_gateway_vpc_attachment.main[0].id : null
}

output "security_group_ids" {
  description = "Map of security group names to IDs"
  value = {
    default    = aws_default_security_group.default.id
    web        = aws_security_group.web.id
    app        = aws_security_group.app.id
    database   = aws_security_group.database.id
    management = aws_security_group.management.id
  }
}

output "network_acl_ids" {
  description = "Map of network ACL names to IDs"
  value = {
    public   = aws_network_acl.public.id
    private  = aws_network_acl.private.id
    isolated = aws_network_acl.isolated.id
  }
}

output "flow_logs_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "flow_logs_log_group_arn" {
  description = "ARN of CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}
