# -----------------------------------------------------------------------------
# CREATE ECR REPOSITORY
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "fapps" {
  name = "fapps"

  tags {
    Name              = "fapps"
    ops_terraformed   = var.ops_terraformed
    ops_environment   = data.template_file.environment.rendered
    ops_service       = data.template_file.service.rendered
  }
}

# -----------------------------------------------------------------------------
# ALLOW UAT AND INTEGRATION ACCOUNT ACCESS TO THE PRODUCTION ECR REPOSITORIES
# -----------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "fapps" {
  repository = aws_ecr_repository.fapps.name
  policy = data.template_file.ecr_policy.rendered
}
