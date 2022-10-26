module "vpc" {
    source               = "terraform-aws-modules/vpc/aws"
    version              = ">= 3.16.0"
    name                 = "eks-vpc"
    cidr                 = "10.0.0.0/16"
    azs                  = ["${var.aws_region}a", "${var.aws_region}b"]
    private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets       = ["10.0.101.0/24", "10.0.102.0/24"]
    enable_nat_gateway   = true
    enable_dns_hostnames = true
    enable_dns_support   = true
    public_subnet_tags   = {"kubernetes.io/role/elb" = "1"}
    private_subnet_tags  = {"kubernetes.io/role/internal-elb" = "1"}
    tags = {
        Terraform   = "true"
        Environment = var.aws_environment
    }
}

module "ecr" {
    source          = "../modules/ecr"
    app_name        = var.app_name
}

module "iam" {
    source                    = "../modules/iam"
    aws_environment           = var.aws_environment
    terraform_service_account = var.terraform_service_account
}

module "eks" {
    source                          = "terraform-aws-modules/eks/aws"
    version                         = ">= 18.30.0"
    cluster_name                    = var.cluster_name
    cluster_version                 = "1.22"
    create_iam_role                 = false
    iam_role_arn                    = module.iam.eks_cluster_role_arn
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
        rolearn  = module.iam.eks_cluster_role_arn
        username = module.iam.eks_cluster_role_name
        },
    ]

    aws_auth_users = [
        {
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.terraform_service_account}"
        }
    ]

    tags = {
        Terraform   = "true"
        Environment = var.aws_environment
    }
}

module "k8" {
    source           = "../modules/k8"
    aws_environment  = var.aws_environment
    cluster_id       = module.eks.cluster_id
    cluster_name     = var.cluster_name
    grafana_admin    = var.grafana_admin
    grafana_password = var.grafana_password
    app_name         = var.app_name
    app_repo         = module.ecr.ecr_repo_url
}

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
        Environment = var.aws_environment
    }
}