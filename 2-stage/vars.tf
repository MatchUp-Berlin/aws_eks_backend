
### AWS Info ###

variable "aws_region" {}

variable "aws_environment" {
  default = "stage"
}

### Cluster Info ###

variable "cluster_name" {
  default = "matchup"
}

### ECR Info ###
variable "app_name" {
  default = "matchup"
}

### Account Info ###

variable "terraform_service_account" {
  default = "terraform"
}

variable "grafana_admin" {
  description = "Grafana administrator username"
  type        = string
  sensitive   = true
}

variable "grafana_password" {
  description = "Grafana administrator password"
  type        = string
  sensitive   = true
}