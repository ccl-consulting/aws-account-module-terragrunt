# AWS Security Hub Configuration
# Enables Security Hub with specified compliance standards and configures aggregation
# Requirement 3.3: Enable AWS Security Hub with specified compliance standards

# Enable Security Hub
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0

  enable_default_standards  = false
  control_finding_generator = "SECURITY_CONTROL"
  auto_enable_controls      = true
}

# Enable AWS Foundational Security Best Practices Standard
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count = var.enable_security_hub && contains(var.compliance_standards, "aws-foundational-security-best-practices") ? 1 : 0

  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# Enable CIS AWS Foundations Benchmark v1.2.0
resource "aws_securityhub_standards_subscription" "cis_1_2" {
  count = var.enable_security_hub && contains(var.compliance_standards, "cis-aws-foundations-benchmark-v1.2") ? 1 : 0

  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.2.0"
}

# Enable CIS AWS Foundations Benchmark v1.4.0
resource "aws_securityhub_standards_subscription" "cis_1_4" {
  count = var.enable_security_hub && contains(var.compliance_standards, "cis-aws-foundations-benchmark-v1.4") ? 1 : 0

  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"
}

# Enable PCI DSS v3.2.1
resource "aws_securityhub_standards_subscription" "pci_dss" {
  count = var.enable_security_hub && contains(var.compliance_standards, "pci-dss") ? 1 : 0

  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
}

# Enable NIST 800-53 Rev. 5
resource "aws_securityhub_standards_subscription" "nist" {
  count = var.enable_security_hub && contains(var.compliance_standards, "nist-800-53") ? 1 : 0

  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-53/v/5.0.0"
}

# Configure Security Hub to send findings to the security account
# This is done through the Security Hub administrator account delegation
# The security account should be configured as the delegated administrator
resource "aws_securityhub_finding_aggregator" "security_account" {
  count = var.enable_security_hub ? 1 : 0

  depends_on = [aws_securityhub_account.main]

  linking_mode = "ALL_REGIONS"
}

# Enable product integrations
# GuardDuty integration
resource "aws_securityhub_product_subscription" "guardduty" {
  count = var.enable_security_hub && var.enable_guardduty ? 1 : 0

  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/guardduty"
}

# AWS Config integration
resource "aws_securityhub_product_subscription" "config" {
  count = var.enable_security_hub && var.enable_config ? 1 : 0

  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/config"
}

# IAM Access Analyzer integration
resource "aws_securityhub_product_subscription" "access_analyzer" {
  count = var.enable_security_hub ? 1 : 0

  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/access-analyzer"
}
