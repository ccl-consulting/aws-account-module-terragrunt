# Network Baseline Module Variables
# Implementation: Task 6

variable "account_id" {
  description = "AWS account ID where the baseline will be deployed"
  type        = string
}

variable "account_name" {
  description = "Name of the AWS account"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "enable_transit_gateway" {
  description = "Enable Transit Gateway attachment"
  type        = bool
  default     = true
}

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway to attach to"
  type        = string
  default     = ""
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "logging_account_id" {
  description = "ID of the centralized logging account"
  type        = string
}

variable "subnet_configuration" {
  description = "Subnet configuration for public, private, and isolated tiers"
  type = object({
    public_subnets   = optional(list(string), [])
    private_subnets  = optional(list(string), [])
    isolated_subnets = optional(list(string), [])
  })
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
