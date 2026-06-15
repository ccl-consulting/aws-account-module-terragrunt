variable "region" {
  description = "The provider main region."
  type        = string
  default     = "eu-west-3"
}

variable "backup_region" {
  description = "The secondary AWS region to store copies of backup from the target region"
  type        = string
  default     = "eu-west-1"
}


variable "governed_regions" {
  description = "The list of regions where the landing zone will be deployed."
  type        = list(string)
  default     = ["eu-west-3"]
}

variable "log_retention_days" {
  description = "Retention period in days for Control Tower logging and access logging buckets."
  type        = number
  default     = 60
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    "Owner"          = "CCL Consulting"
    "Provisioned by" = "Terraform"
  }
}

variable "org_accounts" {
  description = "Organization account structure defining workload and common service accounts"
  type = object({
    workloads = object({
      prod    = list(string)
      staging = list(string)
      dev     = list(string)
      uat     = list(string)
    })
    common_services = list(string)
  })
  default = {
    workloads = {
      prod    = ["prod"]
      staging = ["staging"]
      dev     = ["dev"]
      uat     = ["uat"]
    }
    common_services = []
  }
}

# Emails will use the following format: email_local_part_${account_name}@email_domain to redirect every mail to a single mailbox.
variable "email_local_part" {
  description = "The local part of the email address used for the organization accounts."
  type        = string
  default     = "aws"
}

# Emails will use the following format: email_local_part_${account_name}@email_domain to redirect every mail to a single mailbox.
variable "email_domain" {
  description = "The domain part of the email address used for the organization accounts."
  type        = string
}

variable "full_email" {
  description = "Full email address override per workload environment. When non-empty, replaces the constructed email for that environment's accounts."
  type = object({
    prod    = optional(string, "")
    staging = optional(string, "")
    dev     = optional(string, "")
    uat     = optional(string, "")
  })
  default = {
    prod    = ""
    staging = ""
    dev     = ""
    uat     = ""
  }
}

variable "scps" {
  description = "Map of Service Control Policies to create and attach to OUs or accounts."
  type = map(object({
    name        = string
    description = optional(string, "")
    content     = string
    targets     = list(string)
  }))
  default = {}
}