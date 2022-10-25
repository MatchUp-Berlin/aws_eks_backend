
### Cluster Info ###

output "cluster_id" {
    value       = module.eks.cluster_id
    description = "cluster name"
}

output "cluster_endpoint" {
    value       = module.eks.cluster_endpoint
    description = "endpoint for cluster control plane"
}

### VPC Info ###

output "vpc_private_subnets" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets_cidr_blocks
}

### Load Balancer Hostname ###

output "load_balancer_hostname" {
  value = kubernetes_service.grafana-lb.status.0.load_balancer.0.ingress.0.hostname
}

### ECR Info ####

output "ecr_repo" {
  value = data.aws_ecr_image.matchup_image.repository_name
}