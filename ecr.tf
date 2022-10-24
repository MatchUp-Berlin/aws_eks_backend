resource "aws_ecr_repository" "matchup_ecr" {
  name                 = "matchup"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}