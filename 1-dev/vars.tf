
### AWS Info ###

variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_environment" {
  default = "dev"
}

### Cluster Info ###

variable "cluster_name" {
  default = "matchup"
}

### ECR Info ###
variable "app_name" {
  default = "matchup"
}

variable "app_url" {
  description = "dns for app"
  default = "getmatchup.org"
}

variable "app_name2" {
  default = "matchup-landing"
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