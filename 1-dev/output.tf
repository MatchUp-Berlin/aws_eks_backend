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