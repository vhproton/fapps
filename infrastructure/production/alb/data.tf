# -----------------------------------------------------------------------------
# AWS PROVIDER AND REMOTE STATE
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket  = "production-terraform-state"
    key     = "alb/terraform.tfstate"
    encrypt = "true"
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

# -----------------------------------------------------------------------------
# DATA SOURCES FOR NETWORK RESOURCES
# -----------------------------------------------------------------------------

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "${data.template_file.environment.rendered}-terraform-state"
    key    = "network/terraform.tfstate"
    region = var.aws_region
  }
}
