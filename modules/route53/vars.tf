variable "app_url" {
  description = "dns for app"
  type        = string
}

variable "app_load_balancer_hostname" {
    type = string
}

variable "app2_load_balancer_hostname" {
    type = string
}

variable "app_name" {
  type        = string
}

variable "aws_environment" {
  type = string
}