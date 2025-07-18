# Neuefische AWS Capstone Project

A Terraform-based AWS infrastructure project that deploys a scalable, multi-tier WordPress hosting environment with high availability, load balancing, and automated server configuration.

## Architecture Overview

This project creates a secure, highly available WordPress hosting environment on AWS with the following components:

- **Custom VPC** with public and private subnets across multiple AZs
- **Web Server** (EC2) in public subnet for management access
- **Application Servers** (Auto Scaling Group) in private subnets running WordPress
- **RDS MySQL Database** shared across all app servers
- **Application Load Balancer** with health checks distributing traffic across app servers
- **Auto Scaling Policies** with CPU-based scaling triggers
- **CloudWatch Monitoring** with automatic scaling alarms
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
│                    VPC (10.0.0.0/26) - us-west-2                                    │
│                                                                                     │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────────────┐ │
│  │     AVAILABILITY ZONE A     │    │        AVAILABILITY ZONE B                  │ │
│  │        (us-west-2a)         │    │          (us-west-2b)                       │ │
│  │                             │    │                                             │ │
│  │ ┌─────────────────────────┐ │    │ ┌──────────────────────────────────────┐    │ │
│  │ │   PUBLIC SUBNET 1       │ │    │ │        PUBLIC SUBNET 2               │    │ │
│  │ │    (10.0.0.0/28)        │ │    │ │         (10.0.0.16/28)               │    │ │
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
│  │ │                      (Spans both public subnets)                          │  │ │
│  │ └───────────────────────────────────────────────────────────────────────────┘  │ │
│  │                             │    │                                             │ │
│  │ ┌─────────────────────────┐ │    │ ┌──────────────────────────────────────┐    │ │
│  │ │   PRIVATE SUBNET 1      │ │    │ │       PRIVATE SUBNET 2               │    │ │
│  │ │    (10.0.0.32/28)       │ │    │ │        (10.0.0.48/28)                │    │ │
│  │ │                         │ │    │ │                                      │    │ │
│  │ │  ┌─────────────────┐    │ │    │ │  ┌─────────────────────────────────┐ │    │ │
│  │ │  │   APP SERVER    │    │ │    │ │  │         APP SERVER              │ │    │ │
│  │ │  │  (WordPress)    │    │ │    │ │  │        (WordPress)              │ │    │ │
│  │ │  │                 │    │ │    │ │  │                                 │ │    │ │
│  │ │  └─────────────────┘    │ │    │ │  └─────────────────────────────────┘ │    │ │
|  | |  ┌────────────────────┐ │ │    │ │                                      │    │ │
│  │ │  │      RDS DB        │ │ |    | |                                      │    │ │
│  │ │  │   (MySQL 8.0)      │ │ |    | |                                      │    │ │
│  │ │  └────────────────────┘ | |    | |                                      │    │ │ 
|  │ │  (Accessible only from  | |    | |                                      │    │ │
|  │ │       app servers)      | |    | |                                      │    │ │
|  | |                         | |    | |                                      │    │ │
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
│                        │    (Min: 1, Max: 4)  │                                     │
│                        └──────────────────────┘                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

TRAFFIC FLOW:
─────────────
User Request:  Internet → ALB → App Servers (Private Subnets)
Management:    SSH → Web Server → App Servers → RDS
Database:      App Servers → RDS (MySQL, private access only)
Updates:       App Servers → NAT Gateway → Internet

SECURITY GROUPS:
────────────────
• Web Server SG:    SSH (Your IP), HTTP (0.0.0.0/0)
• ALB SG:           HTTP (0.0.0.0/0)
• App Server SG:    HTTP (ALB only), SSH (Web Server only), MySQL (to RDS only)
• RDS SG:           MySQL (port 3306) from App Server SG only
```

## Infrastructure Components

### Networking
- **VPC**: Custom Virtual Private Cloud (10.0.0.0/26)
- **Public Subnets**: 2 subnets across different AZs (10.0.0.0/28, 10.0.0.16/28)
- **Private Subnets**: 2 subnets across different AZs (10.0.0.32/28, 10.0.0.48/28)
- **Internet Gateway**: Provides internet access for public subnets
- **NAT Gateway**: Enables private subnet internet access
- **Route Tables**: Separate routing for public and private subnets

### Security
- **Web Server Security Group** (`sg_web_server`):
  - SSH (port 22): Restricted to your IP only
  - HTTP (port 80): Open to internet (for management/testing)
  - Outbound: All traffic allowed
- **Application Load Balancer Security Group** (`sg_alb`):
  - HTTP (port 80): Open to internet
  - Outbound: HTTP (port 80) to app servers only
- **App Server Security Group** (`sg_app_server`):
  - HTTP (port 80): From ALB security group only
  - SSH (port 22): From web server security group only
  - Outbound: All traffic allowed (for updates via NAT Gateway)

### Compute
- **AMI Selection**: Automatically uses the latest Amazon Linux 2 AMI via data source
- **Web Server**: Single EC2 instance in public subnet (bastion host for management)
- **App Servers**: Auto Scaling Group (1-4 instances) in private subnets
- **Load Balancer**: Application Load Balancer with health checks distributing traffic
- **Launch Template**: Standardized configuration with SSH key and proper instance tagging
- **Auto Scaling Policies**: CPU-based scaling (scale up >70%, scale down <30%)
- **Target Group**: Automatic registration/deregistration via ASG attachment
- **Auto-configured** with Apache, PHP 8.0, MariaDB, and WordPress

### Monitoring & Auto Scaling
- **Health Checks**: ALB monitors app server health every 30 seconds
- **CloudWatch Alarms**: CPU utilization monitoring with 2-minute evaluation periods
- **Scaling Policies**: Automatic instance addition/removal based on CPU load
- **ELB Health Checks**: Auto Scaling Group uses load balancer health status
- **Cooldown Periods**: 5-minute cooldown between scaling actions

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
   instance_type          = "t2.micro"
   key_name               = "your-key-pair-name"
   vpc_cidr               = "10.0.0.0/26"
   public_subnet_cidrs    = ["10.0.0.0/28", "10.0.0.16/28"]
   private_subnet_cidrs   = ["10.0.0.32/28", "10.0.0.48/28"]
   availability_zones     = ["us-west-2a", "us-west-2b"]
   my_ip                  = "YOUR.IP.ADDRESS/32"
   DB_USERNAME            = "root"
   DB_PASSWORD            = "your-secure-password"
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
- Installs Apache, PHP 8.0, and MariaDB client
- Clones a GitHub repository that contains pre-packed WordPress files (`wordpress-files.tar.gz`) and optionally a SQL dump (`wordpress.sql`)
- Extracts and copies the WordPress files into `/var/www/html`
- Sets proper file permissions for Apache
- Creates the database user (`wpuser`) and grants privileges
- If `wordpress.sql` is present, imports the dump and performs automatic URL updates from `localhost` to the live ALB DNS
- Automatically configures `wp-config.php` with RDS credentials

### Web Server Setup
The web server user data script:
- Updates the system packages
- Installs and starts Apache
- Creates a simple status page

### Database Configuration
- **Database Type**: AWS RDS MySQL 8.0.35
- **Instance Class**: db.t3.micro
- **Database Name**: wordpress
- **Master User**: Configured via `DB_USERNAME` variable
- **Master Password**: Configured via `DB_PASSWORD` variable
- **WordPress User**: wpuser (created automatically)
- **Multi-AZ**: Disabled (single AZ for cost optimization)
- **Storage**: 10GB GP2
- **Backup**: Skip final snapshot enabled

### Auto Scaling Configuration

#### Health Checks
- **Target Group Health Check**: 
  - Path: `/` (WordPress homepage)
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Healthy threshold: 2 consecutive successful checks
  - Unhealthy threshold: 2 consecutive failed checks

#### Scaling Policies
- **Scale Up Policy**:
  - Trigger: CPU utilization > 70%
  - Evaluation: 2 periods of 2 minutes (4 minutes total)
  - Action: Add 1 instance
  - Cooldown: 5 minutes

- **Scale Down Policy**:
  - Trigger: CPU utilization < 30%
  - Evaluation: 2 periods of 2 minutes (4 minutes total)
  - Action: Remove 1 instance
  - Cooldown: 5 minutes

#### Load Balancer Features
- **Cross-Zone Load Balancing**: Enabled by default
- **Health Check Integration**: ASG uses ELB health checks
- **Automatic Target Registration**: New instances automatically join target group
- **Graceful Termination**: Unhealthy instances are drained before termination

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
├── main.tf                    # Terraform configuration and provider requirements
├── provider.tf                # AWS provider configuration
├── variables.tf               # Variable definitions
├── vpc.tf                     # VPC configuration
├── subnet.tf                  # Subnet configurations
├── routetable.tf              # Route tables and associations
├── nat.tf                     # NAT Gateway and Elastic IP
├── sg.tf                      # Security groups (web server, ALB, app servers, RDS)
├── ec2.tf                     # Web server EC2 instance with AMI data source
├── alb.tf                     # Application Load Balancer and target group
├── autoscaling.tf             # Launch template, ASG, scaling policies, CloudWatch alarms
├── db.tf                      # RDS MySQL database and subnet group
├── terraform.tfvars           # Variable values (keep secure!)
├── scripts/
│   ├── userdata_web.sh        # Web server initialization script
│   ├── userdata_app.sh        # App server initialization script with RDS integration
│   └── loadbalancertest.sh    # Load balancer testing script
├── forme.md                   # Detailed architecture explanation
└── README.md                  # This file
```

## Customization

### Scaling Options
- **Auto Scaling Group**: Currently configured for 1-4 instances with CPU-based scaling
- **Scaling Triggers**: 
  - Scale up when CPU > 70% for 4 minutes
  - Scale down when CPU < 30% for 4 minutes
- **Modify thresholds**: Adjust CPU thresholds in CloudWatch alarms
- **Instance types**: Change `instance_type` in variables for more powerful instances
- **Capacity**: Modify min_size, max_size, desired_capacity in ASG
- **Additional metrics**: Add memory, network, or custom application metrics
- **Multi-AZ**: Already spans multiple availability zones for high availability

### Security Enhancements
- Use AWS Systems Manager Session Manager instead of SSH
- Implement AWS WAF for web application protection
- Add CloudWatch monitoring and logging

## Database Management

### Connecting to RDS Database

**Method 1: Via App Server (Recommended)**
```bash
# SSH to web server (bastion)
ssh -i your-key.pem ec2-user@WEB-SERVER-PUBLIC-IP

# SSH to app server
ssh ec2-user@APP-SERVER-PRIVATE-IP

# Connect to RDS
mysql -h RDS-ENDPOINT -u root -p
```

**Method 2: Direct Connection (if RDS is publicly accessible)**
```bash
# Get RDS endpoint
terraform output rds_endpoint

# Connect directly
mysql -h YOUR-RDS-ENDPOINT -u root -p
```

### Database Operations

**Create Backup:**
```bash
mysqldump -h RDS-ENDPOINT -u root -p wordpress > wordpress_backup.sql
```

**Restore Backup:**
```bash
mysql -h RDS-ENDPOINT -u root -p wordpress < wordpress_backup.sql
```

**View WordPress Tables:**
```sql
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;
```

### Infrastructure Organization
The project uses a **modular file structure** for better maintainability:
- **Networking**: `vpc.tf`, `routetable.tf`, `nat.tf` - Network infrastructure
- **Security**: `sg.tf` - All security groups with proper references
- **Compute**: `ec2.tf`, `autoscaling.tf` - Web server and app server configurations
- **Load Balancing**: `alb.tf` - Load balancer, target group, and listener
- **Configuration**: `variables.tf`, `terraform.tfvars` - Variable definitions and values

This modular approach makes it easier to:
- **Understand** the infrastructure components
- **Modify** specific parts without affecting others
- **Debug** issues in isolated components
- **Scale** the infrastructure by adding new modules

## Cleanup

To destroy all created resources:
```bash
terraform destroy
```

## Troubleshooting

### Common Issues
1. **SSH Access Denied**: Verify your IP address in `my_ip` variable
2. **WordPress Not Loading**: Check ALB health checks and target group status
3. **Database Connection Error**: Verify MariaDB service is running on app servers
4. **Auto Scaling Not Working**: Check CloudWatch alarms and scaling policies
5. **Health Check Failures**: Verify WordPress is responding on port 80
6. **Instances Not Joining ALB**: Check target group registration and health status
7. **ALB Health Check Failures**: Verify ALB security group allows outbound HTTP to app servers
8. **Database Connection Error**: 
   - Check RDS security group allows connections from app servers
   - Verify RDS endpoint is accessible from private subnets
   - Check database credentials in terraform.tfvars
9. **Security Group Rule Deletion Error**: If you get GroupId missing errors during destroy:
   ```bash
   # Remove orphaned security group rules from state
   terraform state list | grep aws_vpc_security_group_.*_rule
   terraform state rm <rule_resource_name>
   # Then run destroy again
   terraform destroy
   ```

### Useful Commands
```bash
# Check Terraform state
terraform show

# Get RDS connection details
terraform output

# Validate configuration
terraform validate

# Plan changes
terraform plan

# SSH into web server (bastion)
ssh -i your-key.pem ec2-user@YOUR-WEB-SERVER-PUBLIC-IP

# From web server, SSH to app server
ssh ec2-user@PRIVATE-APP-SERVER-IP

# Check services on app servers
sudo systemctl status httpd

# Connect to RDS from app server
mysql -h RDS-ENDPOINT -u root -p

# Create database backup
mysqldump -h RDS-ENDPOINT -u root -p wordpress > backup.sql

# Monitor Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names asg-app-servers

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn YOUR-TARGET-GROUP-ARN

# View CloudWatch alarms
aws cloudwatch describe-alarms

# Get ALB DNS name
aws elbv2 describe-load-balancer --names app-lb --query 'LoadBalancers[0].DNSName'
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