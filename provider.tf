
# Configure the AWS Provider with variables
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access
  secret_key = var.aws_secret
  token      = var.aws_token
}