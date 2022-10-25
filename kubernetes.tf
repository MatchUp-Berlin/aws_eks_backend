data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

### Kubernetes authentication and connection for Helm Provider ###

provider "helm" {
  kubernetes {
    config_path            = "~/.kube/config"
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

### K8 Load Balancer Controller Helm Chart ###

resource "helm_release" "AWS_Load_Balancer_Controller" {
  name       = "aws-load-balancer-controller"
  chart      = "eks/aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.CLUSTER_NAME
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

### Kubernetes authentication and connection for K8 Provider ###

provider "kubernetes" {
    config_path            = "~/.kube/config"
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
}


