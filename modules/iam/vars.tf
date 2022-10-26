variable "aws_environment" {
  type = string
}

variable "terraform_service_account" {
  type    = string
  default = "terraform"
}

variable "cluster_name" {
  type = string
}