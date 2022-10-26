data "aws_eks_cluster" "cluster" {
    name = var.cluster_id
}

data "aws_ecr_image" "app_image" {
  repository_name = var.app_name
  image_tag       = "latest"
}