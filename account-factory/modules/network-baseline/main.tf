# Network Baseline Module
# This module defines the network baseline configuration for member accounts
# Implementation: Task 6
# Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# This module creates a complete network baseline including:
# - VPC with public, private, and isolated subnets across multiple AZs
# - Internet Gateway and NAT Gateways for internet connectivity
# - Route tables for each subnet tier
# - Transit Gateway attachment for inter-account connectivity
# - Security groups for common use cases (web, app, database, management)
# - Network ACLs for subnet-level security
# - VPC Flow Logs with delivery to CloudWatch Logs
