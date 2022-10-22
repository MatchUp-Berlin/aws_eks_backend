
### AWS Info ###

variable "AWS_REGION" {
  default = "eu-central-1"
}

variable "AWS_ENVIRONMENT" {
  default = "dev"
}

### Cluster Info ###

variable "CLUSTER_NAME" {
  default = "matchup"
}

### Account Info ###

variable "TERRAFORM_SERVICE_ACCOUNT" {
  default = "terraform"
}

variable "GRAFANA_ADMIN" {
  description = "Grafana administrator username"
  type        = string
  sensitive   = true
}

variable "GRAFANA_PASSWORD" {
  description = "Grafana administrator password"
  type        = string
  sensitive   = true
}