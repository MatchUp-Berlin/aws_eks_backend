output "eks_cluster_role_name" {
  value = aws_iam_role.eks-cluster.name
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks-cluster.arn
}

output "karpenter_instance_profile" {
  value = aws_iam_instance_profile.karpenter.name
}