# AWS Landing Zone Terragrunt Examples

This directory contains comprehensive Terragrunt configuration examples for deploying AWS Landing Zones using the CCL Consulting AWS Account Module. Each example is tailored for different organizational needs and deployment scenarios.

## Available Examples

### 1. **Production Landing Zone** (`production-landing-zone.hcl`)
**Use Case**: Large production environments with multiple business units
- Multi-region Control Tower deployment
- Comprehensive account structure (prod, staging, dev)
- Extensive common services accounts
- Enterprise-grade security and compliance tagging
- Advanced remote state configuration with cross-region replication
- Deployment hooks and validations

### 2. **Simple Startup** (`simple-startup.hcl`)
**Use Case**: Small organizations or startups with minimal requirements
- Single region deployment for cost optimization
- Basic account structure (one account per environment)
- Minimal common services
- Cost-optimized configuration
- Simple tagging strategy

### 3. **Enterprise Multi-Region** (`enterprise-multi-region.hcl`)
**Use Case**: Large enterprises with complex multi-region requirements
- Global multi-region deployment (US, EU, APAC)
- Business unit-based account organization
- Extensive shared services portfolio
- Comprehensive compliance and governance tagging
- Advanced deployment automation and validation
- Disaster recovery and business continuity features

### 4. **Development Environment** (`development-environment.hcl`)
**Use Case**: Development and testing environments
- Cost-optimized configuration
- Team-based development accounts
- Auto-shutdown policies
- Simplified monitoring and backup
- Development-specific tagging and governance

## Getting Started

### Prerequisites

Before deploying any landing zone configuration, ensure you have:

1. **AWS Management Account Access**
   - Administrative access to your AWS management account
   - Appropriate IAM permissions for Organizations and Control Tower

2. **Terragrunt Setup**
   ```bash
   # Install Terragrunt
   brew install terragrunt  # macOS
   # or download from https://terragrunt.gruntwork.io/
   
   # Install Terraform
   brew install terraform   # macOS
   ```

3. **Email Domain**
   - A valid email domain for account creation
   - Ability to receive emails at `{prefix}+{account-name}@{domain}`

4. **State Storage**
   - S3 bucket for Terraform state
   - DynamoDB table for state locking

### Basic Deployment Steps

1. **Choose Your Example**
   ```bash
   cp examples/simple-startup.hcl my-deployment.hcl
   ```

2. **Customize Configuration**
   ```hcl
   # Update email domain
   email_domain = "your-company.com"
   
   # Customize account structure
   org_accounts = {
     workloads = {
       prod = ["your-prod-account"]
       # ... customize as needed
     }
   }
   ```

3. **Validate Configuration**
   ```bash
   terragrunt validate
   ```

4. **Plan Deployment**
   ```bash
   terragrunt plan
   ```

5. **Deploy Landing Zone**
   ```bash
   terragrunt apply
   ```

## Architecture Overview

The landing zone module creates the following AWS resources:

### Core Components
- **AWS Organizations**: Root organization with OUs
- **AWS Control Tower**: Landing zone with governance
- **Account Structure**: Automated account creation
- **IAM Roles**: Control Tower service roles
- **Backup Configuration**: Cross-account backup policies

### Organizational Units (OUs)
```
Root Organization
├── Security Account (mandatory)
├── Logging Account (mandatory)
├── Suspended OU
├── Common Services OU
│   ├── Backups Account
│   └── Custom Service Accounts
└── Workloads OU
    ├── Production OU
    ├── Staging OU
    └── Development OU
```

### Account Types

| Account Type | Purpose | Examples |
|--------------|---------|----------|
| **Management** | Root account for billing and organization management | (Your existing account) |
| **Security** | Centralized security and audit logging | AWS Config, Security Hub |
| **Logging** | Centralized logging and CloudTrail | CloudTrail, Access Logs |
| **Backups** | Cross-account backup management | AWS Backup policies |
| **Workload** | Application and service accounts | Production, Staging, Development |
| **Common Services** | Shared infrastructure services | Networking, DNS, Monitoring |

## Configuration Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `email_domain` | Domain for account emails | `"company.com"` |
| `region` | Primary AWS region | `"us-east-1"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `backup_region` | Secondary region for backups | `"us-west-2"` |
| `governed_regions` | Control Tower managed regions | `["us-east-1"]` |
| `email_local_part` | Email prefix | `"aws"` |
| `org_accounts` | Account structure definition | See examples |
| `tags` | Resource tags | Basic tags |

### Email Configuration

Accounts are created with emails in the format:
```
{email_local_part}+{account-name}@{email_domain}
```

Examples:
- `aws+prod-web-services@company.com`
- `aws+security@company.com`
- `aws+logging@company.com`

## Security Best Practices

### 1. **Least Privilege Access**
- Use specific IAM roles for Terragrunt execution
- Implement proper assume role chains
- Regular access reviews

### 2. **State File Security**
- Encrypt state files at rest and in transit
- Use separate state buckets per environment
- Implement proper access controls on state buckets

### 3. **Network Security**
- Deploy in private subnets when possible
- Use VPC endpoints for AWS services
- Implement proper security group rules

### 4. **Compliance and Governance**
- Implement comprehensive tagging strategies
- Use AWS Config for compliance monitoring
- Regular security assessments

### 5. **Backup and Recovery**
- Cross-region backup replication
- Regular backup testing
- Documented recovery procedures

## Tagging Strategy

### Required Tags
- `Owner`: Resource owner
- `Environment`: Environment type (prod, staging, dev)
- `CostCenter`: Cost allocation
- `Provisioned by`: Terraform/Terragrunt

### Recommended Tags
- `Project`: Project identifier
- `DataClass`: Data classification level
- `Backup`: Backup requirement flag
- `Monitoring`: Monitoring level
- `Compliance`: Compliance requirements

### Example Tagging Configuration
```hcl
tags = {
  # Basic information
  "Owner"           = "Platform Team"
  "Environment"     = "Production"
  "CostCenter"      = "Infrastructure"
  "Provisioned by"  = "Terraform"
  
  # Governance
  "Project"         = "Landing Zone"
  "DataClass"       = "Internal"
  "Backup"          = "true"
  "Monitoring"      = "Enhanced"
  
  # Compliance
  "SecurityLevel"   = "High"
  "Compliance"      = "SOC2,ISO27001"
  
  # Contact
  "TechnicalOwner"  = "platform-team@company.com"
}
```

## Common Issues and Troubleshooting

### 1. **Control Tower Prerequisites**
**Error**: Control Tower deployment fails
**Solution**: Ensure your management account meets all Control Tower prerequisites:
- No existing Control Tower deployment
- Proper IAM permissions
- Account in good standing

### 2. **Email Domain Issues**
**Error**: Account creation fails due to email conflicts
**Solution**: 
- Use a dedicated subdomain for AWS accounts
- Ensure email routing is configured properly
- Avoid using existing email addresses

### 3. **Regional Limitations**
**Error**: Service not available in selected region
**Solution**: 
- Verify Control Tower regional availability
- Use supported regions for governed_regions
- Check service availability in target regions

### 4. **State File Conflicts**
**Error**: State locking errors
**Solution**:
- Ensure DynamoDB table exists and is accessible
- Use unique state keys for different deployments
- Implement proper IAM permissions for state access

### 5. **Large Deployment Timeouts**
**Error**: Terraform timeouts during large deployments
**Solution**:
- Increase terraform timeout values
- Deploy in phases (core first, then workloads)
- Use depends_on properly to manage resource order

## Additional Resources

### Documentation
- [AWS Control Tower User Guide](https://docs.aws.amazon.com/controltower/)
- [AWS Organizations User Guide](https://docs.aws.amazon.com/organizations/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)

### AWS Well-Architected
- [Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- [Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/)
- [Operational Excellence Pillar](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/)

### Best Practices
- [AWS Account Setup Best Practices](https://aws.amazon.com/organizations/getting-started/best-practices/)
- [Multi-Account Strategy](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/)

## Contributing

To contribute new examples or improvements:

1. Follow the existing example structure
2. Include comprehensive comments
3. Test configurations in a development environment
4. Update this README with new examples
5. Submit a pull request with detailed description

## Support

For questions and support:
- **Technical Issues**: Create an issue in the repository
- **CCL Consulting**: Contact our cloud architecture team
- **AWS Support**: Use your AWS support plan for service-specific issues

---

**Important Notes:**
- Always test configurations in a development environment first
- Review all configurations before applying to production
- Ensure you have proper backup and recovery procedures
- Monitor costs and usage regularly
- Keep Terraform and Terragrunt versions updated
