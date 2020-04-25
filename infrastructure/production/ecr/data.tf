# -----------------------------------------------------------------------------
# AWS PROVIDER AND REMOTE STATE
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket  = "production-terraform-state"
    key     = "ecr/terraform.tfstate"
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
# ECR ACCESS POLICY (GRANT UAT AND INTEGRATION ACCOUNTS ACCESS TO THE PRODUCTION ECR REPOSITORIES)
# -----------------------------------------------------------------------------

data "template_file" "ecr_policy" {
  template = file("templates/ecr-policy")
}
