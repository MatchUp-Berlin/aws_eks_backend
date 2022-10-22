
### Creation of IAM Role for Cluster ###

resource "aws_iam_role" "eks-cluster" {
  name = "eks_cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [ "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
                          "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
                          "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
                          "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"]

  tags = {
    Terraform   = "true"
    Environment = var.AWS_ENVIRONMENT
  }
}

### load balancer controller IAM Role for Service Account ###

module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = var.AWS_ENVIRONMENT
  }
}