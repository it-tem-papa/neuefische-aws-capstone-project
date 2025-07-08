# Neuefische AWS Capstone Project

A Terraform-based AWS infrastructure project that deploys a complete WordPress hosting environment with custom VPC, security groups, and automated server configuration.

## Architecture Overview

This project creates a secure, scalable WordPress hosting environment on AWS with the following components:

- **Custom VPC** with public subnet
- **EC2 instance** running Amazon Linux 2
- **Security Groups** with controlled access
- **Internet Gateway** and routing configuration
- **Automated WordPress installation** via user data script

## Infrastructure Components

### Networking
- **VPC**: Custom Virtual Private Cloud (10.0.0.0/16)
- **Public Subnet**: 10.0.1.0/24 in us-west-2a
- **Internet Gateway**: Provides internet access
- **Route Table**: Routes traffic to internet gateway

### Security
- **Security Group** with the following rules:
  - SSH (port 22): Restricted to your IP
  - HTTP (port 80): Open to internet
  - HTTPS (port 443): Open to internet
  - Custom (port 8080): Open to internet
  - MySQL (port 3306): VPC internal only

### Compute
- **EC2 Instance**: t2.micro Amazon Linux 2
- **Auto-configured** with Apache, PHP, MariaDB, and WordPress

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS CLI configured or AWS credentials
- An existing EC2 Key Pair in your AWS account
- Your public IP address for SSH access

## Quick Start

1. **Clone and navigate to the project**:
   ```bash
   cd neuefische-aws-capstone-project
   ```

2. **Configure variables**:
   Update `terraform.tfvars` with your specific values:
   ```hcl
   aws_region            = "us-west-2"
   ami_id                = "ami-040361ed8686a66a2"  # Amazon Linux 2
   instance_type         = "t2.micro"
   key_name              = "your-key-pair-name"
   vpc_cidr              = "10.0.0.0/16"
   public_subnet_01_cidr = "10.0.1.0/24"
   my_ip                 = "YOUR.IP.ADDRESS/32"
   aws_access            = "your-access-key"
   aws_secret            = "your-secret-key"
   aws_token             = "your-session-token"  # If using temporary credentials
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access your WordPress site**:
   - Find your EC2 instance's public IP in the AWS console
   - Navigate to `http://YOUR-EC2-PUBLIC-IP`
   - Complete the WordPress setup wizard

## Configuration Details

### WordPress Setup
The user data script automatically:
- Updates the system packages
- Installs Apache, PHP 8.0, and MariaDB
- Downloads and configures WordPress
- Creates a WordPress database and user
- Sets proper file permissions

### Database Configuration
- **Database**: wordpress
- **User**: wpuser
- **Password**: wppassword (change in production!)

### Security Considerations

⚠️ **Important Security Notes**:
- Change default database credentials before production use
- Consider using AWS RDS for production databases
- Implement SSL/TLS certificates for HTTPS
- Use AWS Secrets Manager for sensitive data
- Remove hardcoded credentials from terraform.tfvars

## File Structure

```
.
├── main.tf              # Terraform configuration and provider requirements
├── provider.tf          # AWS provider configuration
├── variables.tf         # Variable definitions
├── vpc.tf              # VPC, subnets, security groups, and networking
├── ec2.tf              # EC2 instance configuration
├── terraform.tfvars    # Variable values (keep secure!)
├── scripts/
│   └── userdata.sh     # EC2 initialization script
└── README.md           # This file
```

## Customization

### Scaling Options
- Change `instance_type` in variables for more powerful instances
- Add additional subnets for multi-AZ deployment
- Implement Auto Scaling Groups for high availability

### Security Enhancements
- Use AWS Systems Manager Session Manager instead of SSH
- Implement AWS WAF for web application protection
- Add CloudWatch monitoring and logging

## Cleanup

To destroy all created resources:
```bash
terraform destroy
```

## Troubleshooting

### Common Issues
1. **SSH Access Denied**: Verify your IP address in `my_ip` variable
2. **WordPress Not Loading**: Check security group rules and EC2 status
3. **Database Connection Error**: Verify MariaDB service is running

### Useful Commands
```bash
# Check Terraform state
terraform show

# SSH into EC2 instance
ssh -i your-key.pem ec2-user@YOUR-EC2-PUBLIC-IP

# Check Apache status
sudo systemctl status httpd

# Check MariaDB status
sudo systemctl status mariadb
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the terms specified in the LICENSE file.

---

**Note**: This is a learning project for AWS and Terraform. For production use, implement additional security measures, monitoring, and backup strategies.