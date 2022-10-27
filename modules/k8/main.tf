
### Namespaces ###

resource "kubernetes_namespace" "prometheus" {
    metadata {
        name = "prometheus"
    }
}

resource "kubernetes_namespace" "app" {
    metadata {
        name = var.app_name
    }
}

### Helm Charts ###

resource "helm_release" "AWS_Load_Balancer_Controller" {
    name       = "aws-load-balancer-controller"
    chart      = "eks/aws-load-balancer-controller"
    namespace  = "kube-system"

    set {
    name  = "clusterName"
    value = var.cluster_name
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

resource "helm_release" "prometheus" {
    name       = "prometheus"
    chart      = "prometheus-community/prometheus"
    version    = "15.16.1"
    namespace  = "prometheus"
}

resource "helm_release" "grafana" {
    name       = "grafana"
    chart      = "grafana/grafana"
    version    = "6.42.2"
    namespace  = "prometheus"

    set {
        name  = "adminUser"
        value = var.grafana_admin
    }

    set {
        name  = "adminPassword"
        value = var.grafana_password
    }
}

resource "helm_release" "karpenter" {
    namespace        = "karpenter"
    create_namespace = true

    name       = "karpenter"
    repository = "oci://public.ecr.aws/karpenter"
    chart      = "karpenter"
    version    = "v0.18.1"

    set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.karpenter_role_arn
    }

    set {
    name  = "clusterName"
    value = var.cluster_name
    }

    set {
    name  = "clusterEndpoint"
    value = var.cluster_endpoint
    }

    set {
    name  = "aws.defaultInstanceProfile"
    value = var.karpenter_instance_profile
    }
}

### Deployments ###

resource "kubernetes_deployment" "app" {
    metadata {
        name      = var.app_name
        namespace = kubernetes_namespace.app.metadata[0].name
    }
    spec {
    selector {
        match_labels = {
        app = var.app_name
        }
    }
    template {
        metadata {
            labels = {
                app = var.app_name
            }
        }
        spec {
            container {
                image = "${var.app_repo}:latest"
                name  = var.app_name
                port {
                    container_port = var.app_port
                }
            }
        }
    }
    }
}

### Services ###

resource "kubernetes_service" "grafana-lb" {
    metadata {
        name      = "grafana-lb"
        namespace = "prometheus"
    }
    spec {
        selector = {
            "app.kubernetes.io/name" = "grafana"
    }
    port {
        port        = 80
        target_port = 3000
    }
        type = "LoadBalancer"
    }
}

resource "kubernetes_service" "app-lb" {
    metadata {
        name      = "${var.app_name}-lb"
        namespace = kubernetes_namespace.app.metadata[0].name
    }
    spec {
        selector = {
            "app" = var.app_name
        }
        port {
            port        = 80
            target_port = var.app_port
        }
        type = "LoadBalancer"
    }
}

### Horizontal Autoscaler ###

resource "kubernetes_horizontal_pod_autoscaler" "horizontalautoscaler" {
    metadata {
        name = "horizontal-autoscaler"
        namespace = "kube-system"
    }

    spec {
        max_replicas = 10
        min_replicas = 1

        scale_target_ref {
            kind = "Deployment"
            name = var.app_name
        }
    }
}

### Provisioners ###

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: default
  spec:
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot"]
    limits:
      resources:
        cpu: 1000
    provider:
      subnetSelector:
        Name: "*private*"
      securityGroupSelector:
        karpenter.sh/discovery/${var.cluster_name}: ${var.cluster_name}
      tags:
        karpenter.sh/discovery/${var.cluster_name}: ${var.cluster_name}
    ttlSecondsAfterEmpty: 30
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}