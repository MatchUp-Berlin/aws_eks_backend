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
    public_subnet_tags   = {
        "kubernetes.io/role/elb" = "1",
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        }
    private_subnet_tags  = {
        "kubernetes.io/role/internal-elb" = "1",
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        }
    tags = {
        Terraform   = "true"
        Environment = var.aws_environment
    }
}

module "iam" {
    source                    = "../modules/iam"
    aws_environment           = var.aws_environment
    terraform_service_account = var.terraform_service_account
    cluster_name              = var.cluster_name
    eks_node_group_iam_role   = module.eks.eks_managed_node_groups["node_group1"].iam_role_name
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
    ingress_load_balancer_controller = {
        description                   = "allow access from control plane to aws load balancer controller"
        protocol                      = "tcp"
        from_port                     = 9443
        to_port                       = 9443
        type                          = "ingress"
        source_cluster_security_group = true
        }
    ingress_nodes_karpenter_port = {
        description                   = "Cluster API to Node group for Karpenter webhook"
        protocol                      = "tcp"
        from_port                     = 8443
        to_port                       = 8443
        type                          = "ingress"
        source_cluster_security_group = true
        }
    ingress_prometheus = {
        description                  = "prometheus ingress"
        protocol                     = "tcp"
        from_port                    = 9090
        to_port                      = 9090
        type                         = "ingress"
        self                         = true
        }
    egress_prometheus = {
        description                  = "prometheus egress"
        protocol                     = "tcp"
        from_port                    = 9090
        to_port                      = 9090
        type                         = "egress"
        cidr_blocks                  = module.vpc.private_subnets_cidr_blocks
        }
    }

    node_security_group_tags = {
        "karpenter.sh/discovery/${var.cluster_name}" = var.cluster_name
    }

    eks_managed_node_groups = {
        node_group1 = {
            name           = "node_group1"
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
        # This will tag the launch template created for use by Karpenter
        "karpenter.sh/discovery/${var.cluster_name}" = var.cluster_name
    }
}

module "k8" {
    source                            = "../modules/k8"
    aws_environment                   = var.aws_environment
    cluster_id                        = module.eks.cluster_id
    cluster_name                      = var.cluster_name
    cluster_endpoint                  = module.eks.cluster_endpoint
    grafana_admin                     = var.grafana_admin
    grafana_password                  = var.grafana_password
    app_name                          = var.app_name
    app_repo                          = data.aws_ecr_repository.app.repository_url
    app_name2                         = var.app_name2
    app_repo2                         = data.aws_ecr_repository.app2.repository_url
    karpenter_instance_profile        = module.iam.karpenter_instance_profile
    karpenter_role_arn                = module.karpenter_irsa.iam_role_arn
    load_balancer_controller_role_arn = module.load_balancer_controller_irsa_role.iam_role_arn
    cert_arn                          = module.route53.cert_arn
}

module "route53" {
    source                      = "../modules/route53"
    aws_environment             = var.aws_environment
    app_url                     = var.app_url
    app_name                    = var.app_name
    app_load_balancer_hostname  = module.k8.app_load_balancer_hostname
    app2_load_balancer_hostname = module.k8.app2_load_balancer_hostname
}

module "load_balancer_controller_irsa_role" {
    source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
    version = "5.3.3"
    role_name                              = "aws-load-balancer-controller"
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

module "karpenter_irsa" {
    source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
    version = "5.3.3"
    role_name                               = "${var.cluster_name}-karpenter"
    attach_karpenter_controller_policy      = true
    karpenter_tag_key                       = "karpenter.sh/discovery/${var.cluster_name}"
    karpenter_controller_cluster_id         = module.eks.cluster_id

    karpenter_controller_ssm_parameter_arns = [
        "arn:aws:ssm:*:*:parameter/aws/service/*"
    ]

    karpenter_controller_node_iam_role_arns = [
        module.eks.eks_managed_node_groups["node_group1"].iam_role_arn
    ]

    oidc_providers = {
        ex = {
            provider_arn               = module.eks.oidc_provider_arn
            namespace_service_accounts = ["karpenter:karpenter"]
        }
    }
}
