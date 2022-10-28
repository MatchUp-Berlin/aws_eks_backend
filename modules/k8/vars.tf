variable "aws_environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_endpoint" {
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

variable "app_name2" {
  type        = string
}

variable "app_repo2" {
  description = "ecr repo url for matchup image"
  type        = string
}

variable "app_port2" {
  description = "container port for app"
  default     = 3000
}

variable "karpenter_instance_profile" {
  type = string
}

variable "karpenter_role_arn" {
  type = string
}

variable "load_balancer_controller_role_arn" {
  type = string
}