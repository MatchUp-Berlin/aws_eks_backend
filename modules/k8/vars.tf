variable "aws_environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_id" {
  type = string
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

variable "app_name" {
    type        = string
}

variable "app_repo" {
    description = "ecr repo url for matchup image"
    type        = string
}

variable "app_port" {
    description = "container port for app"
    default     = 3000
}