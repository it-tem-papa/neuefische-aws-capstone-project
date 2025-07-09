# Neuefische AWS Capstone Project

A Terraform-based AWS infrastructure project that deploys a scalable, multi-tier WordPress hosting environment with high availability, load balancing, and automated server configuration.

## Architecture Overview

This project creates a secure, highly available WordPress hosting environment on AWS with the following components:

- **Custom VPC** with public and private subnets across multiple AZs
- **Web Server** (EC2) in public subnet for management access
- **Application Servers** (Auto Scaling Group) in private subnets running WordPress
- **Application Load Balancer** distributing traffic across app servers
- **NAT Gateway** for private subnet internet access
- **Security Groups** with layered security controls
- **Automated WordPress installation** via user data scripts

## VPC Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                 INTERNET                                            │
└─────────────────────────────────────┬───────────────────────────────────────────────┘
                                      │
┌─────────────────────────────────────┴───────────────────────────────────────────────┐
│                              INTERNET GATEWAY                                       │
└─────────────────────────────────────┬───────────────────────────────────────────────┘
                                      │
┌─────────────────────────────────────┴───────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16) - us-west-2                                    │
│                                                                                     │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────────────┐ │
│  │     AVAILABILITY ZONE A     │    │        AVAILABILITY ZONE B                  │ │
│  │        (us-west-2a)         │    │          (us-west-2b)                       │ │
│  │                             │    │                                             │ │
│  │ ┌─────────────────────────┐ │    │ ┌──────────────────────────────────────┐    │ │
│  │ │   PUBLIC SUBNET 1       │ │    │ │        PUBLIC SUBNET 2               │    │ │
│  │ │    (10.0.1.0/24)        │ │    │ │         (10.0.2.0/24)                │    │ │
│  │ │                         │ │    │ │                                      │    │ │
│  │ │  ┌─────────────────┐    │ │    │ │                                      │    │ │
│  │ │  │   WEB SERVER    │    │ │    │ │                                      │    │ │
│  │ │  │   (Management)  │    │ │    │ │                                      │    │ │
│  │ │  │                 │    │ │    │ │                                      │    │ │
│  │ │  └─────────────────┘    │ │    │ │                                      │    │ │
│  │ │                         │ │    │ │                                      │    │ │
│  │ │  ┌─────────────────┐    │ │    │ │                                      │    │ │
│  │ │  │   NAT GATEWAY   │    │ │    │ │                                      │    │ │
│  │ │  └─────────────────┘    │ │    │ │                                      │    │ │
│  │ └─────────────────────────┘ │    │ └──────────────────────────────────────┘    │ │
│  │                             │    │                                             │ │
│  │                             │    │                                             │ │
│  │ ┌───────────────────────────────────────────────────────────────────────────┐  │ │
│  │ │                    APPLICATION LOAD BALANCER (ALB)                        │  │ │
│  │ │                   (Spans both public subnets)                             │  │ │
│  │ └───────────────────────────────────────────────────────────────────────────┘  │ │
│  │                             │    │                                             │ │
│  │ ┌─────────────────────────┐ │    │ ┌──────────────────────────────────────┐    │ │
│  │ │   PRIVATE SUBNET 1      │ │    │ │       PRIVATE SUBNET 2               │    │ │
│  │ │    (10.0.3.0/24)        │ │    │ │        (10.0.4.0/24)                 │    │ │
│  │ │                         │ │    │ │                                      │    │ │
│  │ │  ┌─────────────────┐    │ │    │ │  ┌─────────────────────────────────┐ │    │ │
│  │ │  │   APP SERVER    │    │ │    │ │  │         APP SERVER              │ │    │ │
│  │ │  │  (WordPress)    │    │ │    │ │  │        (WordPress)              │ │    │ │
│  │ │  │                 │    │ │    │ │  │                                 │ │    │ │
│  │ │  └─────────────────┘    │ │    │ │  └─────────────────────────────────┘ │    │ │
│  │ │           │             │ │    │ │                │                     │    │ │
│  │ │           │             │ │    │ │                │                     │    │ │
│  │ └───────────┼─────────────┘ │    │ └────────────────┼─────────────────────┘    │ │
│  │             │               │    │                  │                          │ │
│  └─────────────┼───────────────┘    └──────────────────┼──────────────────────────┘ │
│                │                                       │                            │
│                └───────────────────┬───────────────────┘                            │
│                                    │                                                │
│                        ┌───────────┴──────────┐                                     │
│                        │   AUTO SCALING GROUP │                                     │
│                        │    (Min: 1, Max: 3)  │                                     │
│                        └──────────────────────┘                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

TRAFFIC FLOW:
─────────────
User Request:  Internet → ALB → App Servers (Private Subnets)
Management:    SSH → Web Server → App Servers (if needed)
Updates:       App Servers → NAT Gateway → Internet

SECURITY GROUPS:
────────────────
• Web Server SG:    SSH (Your IP), HTTP (0.0.0.0/0)
• ALB SG:           HTTP (0.0.0.0/0)
• App Server SG:    HTTP (ALB only), SSH (Web Server only)
```

## Infrastructure Components

### Networking
- **VPC**: Custom Virtual Private Cloud (configurable CIDR)
- **Public Subnets**: 2 subnets across different AZs (default: 10.0.1.0/24, 10.0.2.0/24)
- **Private Subnets**: 2 subnets across different AZs (default: 10.0.3.0/24, 10.0.4.0/24)
- **Internet Gateway**: Provides internet access for public subnets
- **NAT Gateway**: Enables private subnet internet access
- **Route Tables**: Separate routing for public and private subnets

### Security
- **Web Server Security Group**:
  - SSH (port 22): Restricted to your IP
  - HTTP (port 80): Open to internet
- **Application Load Balancer Security Group**:
  - HTTP (port 80): Open to internet
- **App Server Security Group**:
  - HTTP (port 80): From ALB only
  - SSH (port 22): From web server only

### Compute
- **Web Server**: Single EC2 instance in public subnet for management
- **App Servers**: Auto Scaling Group (1-3 instances) in private subnets
- **Load Balancer**: Application Load Balancer distributing traffic
- **Launch Template**: Standardized configuration for app servers
- **Auto-configured** with Apache, PHP 8.0, MariaDB, and WordPress

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
   aws_region             = "us-west-2"
   ami_id                 = "ami-040361ed8686a66a2"  # Amazon Linux 2
   instance_type          = "t2.micro"
   key_name               = "your-key-pair-name"
   vpc_cidr               = "10.0.0.0/16"
   public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
   private_subnet_cidrs   = ["10.0.3.0/24", "10.0.4.0/24"]
   availability_zones     = ["us-west-2a", "us-west-2b"]
   my_ip                  = "YOUR.IP.ADDRESS/32"
   aws_access             = "your-access-key"
   aws_secret             = "your-secret-key"
   aws_token              = "your-session-token"  # If using temporary credentials
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access your WordPress site**:
   - Find your Application Load Balancer's DNS name in the AWS console
   - Navigate to `http://YOUR-ALB-DNS-NAME`
   - Complete the WordPress setup wizard
   
5. **Management Access**:
   - SSH to the web server for management tasks
   - App servers are in private subnets (accessible via web server as bastion)

## Configuration Details

### WordPress Setup
The app server user data script automatically:
- Updates the system packages
- Installs Apache, PHP 8.0, and MariaDB
- Downloads and configures WordPress
- Creates a WordPress database and user
- Sets proper file permissions

### Web Server Setup
The web server user data script:
- Updates the system packages
- Installs and starts Apache
- Creates a simple status page

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
├── vpc.tf              # VPC, subnets, security groups, NAT gateway, and networking
├── ec2.tf              # EC2 instances, Auto Scaling Group, and Load Balancer
├── terraform.tfvars    # Variable values (keep secure!)
├── scripts/
│   ├── userdata_web.sh # Web server initialization script
│   └── userdata_app.sh # App server initialization script
└── README.md           # This file
```

## Customization

### Scaling Options
- Modify Auto Scaling Group settings (min_size, max_size, desired_capacity)
- Change `instance_type` in variables for more powerful instances
- Add additional availability zones and subnets
- Configure Auto Scaling policies based on metrics

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