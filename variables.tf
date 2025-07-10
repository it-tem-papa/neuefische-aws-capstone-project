variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "The type of EC2 instance to create"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the key pair to use for the EC2 instance"
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "The availability zone for the resources"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]

}
variable "aws_access" {
  description = "The AWS access key"
  type        = string
  default     = ""
}

variable "aws_secret" {
  description = "The AWS secret key"
  type        = string
  default     = ""
}

variable "aws_token" {
  description = "The AWS session token"
  type        = string
  default     = ""
}

variable "my_ip" {
  description = "Your public IP address in CIDR notation"
  type        = string
  default     = ""

}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "public_subnet_cidrs" {
  description = "The CIDR block for the first subnet"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
  default     = []
}

variable "anywhere_ipv4" {
  description = "The CIDR block to allow access from anywhere"
  type        = string
  default     = "0.0.0.0/0"

}

variable "user_name" {
  description = "The username for SSH access to the EC2 instance"
  type        = string
  default     = ""

}