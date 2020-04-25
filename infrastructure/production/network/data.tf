# -----------------------------------------------------------------------------
# AWS PROVIDER AND REMOTE STATE
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket  = "production-terraform-state"
    key     = "fapps/network/terraform.tfstate"
    encrypt = true
    region  = "eu-west-1"
  }
}

# -----------------------------------------------------------------------------
# GET SERVICE NAME
# -----------------------------------------------------------------------------

data "template_file" "service" {
  template = file("../../../service")
}

# -----------------------------------------------------------------------------
# GET ENVIRONMENT NAME
# -----------------------------------------------------------------------------

data "template_file" "environment" {
  template = file("../environment")
}