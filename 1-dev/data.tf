data "aws_caller_identity" "current" {}

data "aws_ecr_repository" "app" {
  name = var.app_name
}