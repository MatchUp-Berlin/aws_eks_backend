resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
      Terraform   = "true"
      Environment = var.aws_environment
  }
}