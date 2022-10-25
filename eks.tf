
### EKS Cluster Creation - 2 EKS Managed Node Groups ###

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 18.30.0"

  cluster_name                    = var.CLUSTER_NAME
  cluster_version                 = "1.22"
  create_iam_role                 = false
  iam_role_arn                    = aws_iam_role.eks-cluster.arn
  enable_irsa                     = true

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets

  node_security_group_additional_rules = {
    ingress = {
      description = "allow access from control plane to aws load balancer controller"
      protocol    = "tcp"
      from_port   = 9443
      to_port     = 9443
      type        = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_groups = {
     worker_one = {
      name           = "worker_one"
      instance_types = ["t3.small"]
      min_size       = 2
      desired_size   = 2
      max_size       = 3
     }
  }

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks-cluster.arn
      username = aws_iam_role.eks-cluster.name
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.TERRAFORM_SERVICE_ACCOUNT}"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = var.AWS_ENVIRONMENT
  }
}
