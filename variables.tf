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
    })
    common_services = list(string)
  })
  default = {
    workloads = {
      prod    = ["prod"]
      staging = ["staging"]
      dev     = ["dev"]
    }
    common_services = []
  }
}

# Emails will use the following format: email_local_part+${account_name}@email_domain to redirect every mail to a single mailbox.
variable "email_local_part" {
  description = "The local part of the email address used for the organization accounts."
  type        = string
  default     = "aws"
}

# Emails will use the following format: email_local_part+${account_name}@email_domain to redirect every mail to a single mailbox.
variable "email_domain" {
  description = "The domain part of the email address used for the organization accounts."
  type        = string
}
