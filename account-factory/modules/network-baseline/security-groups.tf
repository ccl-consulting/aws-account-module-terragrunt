# Security Groups and Network ACLs
# Default security groups for common use cases
# Requirements: 4.5

# Default Security Group - Deny all by default
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress or egress rules - deny all traffic
  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-default-sg"
    }
  )
}

# Web Tier Security Group
resource "aws_security_group" "web" {
  name        = "${var.account_name}-web-sg"
  description = "Security group for web tier (HTTP/HTTPS)"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-web-sg"
      Tier = "Web"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "Allow HTTP from anywhere"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "Allow HTTPS from anywhere"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Application Tier Security Group
resource "aws_security_group" "app" {
  name        = "${var.account_name}-app-sg"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-app-sg"
      Tier = "Application"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id = aws_security_group.app.id
  description       = "Allow traffic from web tier"

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.web.id
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Database Tier Security Group
resource "aws_security_group" "database" {
  name        = "${var.account_name}-database-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-database-sg"
      Tier = "Database"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id = aws_security_group.database.id
  description       = "Allow traffic from application tier"

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "db_all" {
  security_group_id = aws_security_group.database.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Management Security Group (for bastion/jump hosts)
resource "aws_security_group" "management" {
  name        = "${var.account_name}-management-sg"
  description = "Security group for management/bastion hosts"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-management-sg"
      Tier = "Management"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "mgmt_ssh" {
  security_group_id = aws_security_group.management.id
  description       = "Allow SSH from VPC"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "mgmt_rdp" {
  security_group_id = aws_security_group.management.id
  description       = "Allow RDP from VPC"

  from_port   = 3389
  to_port     = 3389
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "mgmt_all" {
  security_group_id = aws_security_group.management.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Network ACLs for Public Subnets
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-public-nacl"
      Tier = "Public"
    }
  )
}

# Public NACL - Allow all inbound
resource "aws_network_acl_rule" "public_inbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Public NACL - Allow all outbound
resource "aws_network_acl_rule" "public_outbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Network ACLs for Private Subnets
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-private-nacl"
      Tier = "Private"
    }
  )
}

# Private NACL - Allow all inbound
resource "aws_network_acl_rule" "private_inbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Private NACL - Allow all outbound
resource "aws_network_acl_rule" "private_outbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Network ACLs for Isolated Subnets
resource "aws_network_acl" "isolated" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.isolated[*].id

  tags = merge(
    var.tags,
    {
      Name = "${var.account_name}-isolated-nacl"
      Tier = "Isolated"
    }
  )
}

# Isolated NACL - Allow VPC traffic inbound
resource "aws_network_acl_rule" "isolated_inbound_vpc" {
  network_acl_id = aws_network_acl.isolated.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# Isolated NACL - Allow VPC traffic outbound
resource "aws_network_acl_rule" "isolated_outbound_vpc" {
  network_acl_id = aws_network_acl.isolated.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# Isolated NACL - Allow Transit Gateway traffic inbound (if enabled)
resource "aws_network_acl_rule" "isolated_inbound_tgw" {
  count = var.enable_transit_gateway && var.transit_gateway_id != "" ? 1 : 0

  network_acl_id = aws_network_acl.isolated.id
  rule_number    = 110
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/8"
}

# Isolated NACL - Allow Transit Gateway traffic outbound (if enabled)
resource "aws_network_acl_rule" "isolated_outbound_tgw" {
  count = var.enable_transit_gateway && var.transit_gateway_id != "" ? 1 : 0

  network_acl_id = aws_network_acl.isolated.id
  rule_number    = 110
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/8"
}
