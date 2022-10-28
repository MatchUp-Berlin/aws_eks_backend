
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

    set {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.load_balancer_controller_role_arn
    }
}

resource "helm_release" "metrics-server" {
    name       = "metrics-server"
    chart      = "metrics-server/metrics-server"
    version    = "3.8.2"
    namespace  = "kube-system"

    set {
        name = "args[0]"
        value = "--kubelet-insecure-tls=true"
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
    set {
        name  = "ingress.enabled"
        value = true
    }
    set {
        name  = "ingress.hosts[0]"
        value = kubernetes_ingress_v1.grafana-alb.status.0.load_balancer.0.ingress.0.hostname
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

resource "kubernetes_deployment" "app2" {
    metadata {
        name      = var.app_name2
        namespace = kubernetes_namespace.app.metadata[0].name
    }
    spec {
    selector {
        match_labels = {
        app = var.app_name2
        }
    }
    template {
        metadata {
            labels = {
                app = var.app_name2
            }
        }
        spec {
            container {
                image = "${var.app_repo2}:latest"
                name  = var.app_name2
                port {
                    container_port = var.app_port2
                }
            }
        }
    }
    }
}

### Services ###

resource "kubernetes_service" "grafana-nodeport" {
  metadata {
    name = "grafana-nodeport"
    namespace = "prometheus"
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
    type = "NodePort"
  }
}

resource "kubernetes_service" "app-nodeport" {
  metadata {
    name = "${var.app_name}-nodeport"
    namespace = var.app_name
  }
  spec {
    selector = {
      "app" = var.app_name
    }
    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
    type = "NodePort"
  }
}

resource "kubernetes_service" "app2-nodeport" {
  metadata {
    name = "${var.app_name2}-nodeport"
    namespace = var.app_name
  }
  spec {
    selector = {
      "app" = var.app_name2
    }
    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
    type = "NodePort"
  }
}

### Ingress ALB ###

resource "kubernetes_ingress_v1" "grafana-alb" {
    wait_for_load_balancer = true
    metadata {
        name      = "grafana-alb"
        namespace = "prometheus"
            annotations = {
                "kubernetes.io/ingress.class" = "alb",
                "alb.ingress.kubernetes.io/scheme" = "internet-facing",
                "alb.ingress.kubernetes.io/target-type" = "ip"
            }
    }
    spec {
        rule {
            http {
                path {
                    path = "/*"
                    backend {
                        service {
                            name = kubernetes_service.grafana-nodeport.metadata.0.name
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_ingress_v1" "app-alb" {
    wait_for_load_balancer = true
    metadata {
        name      = "${var.app_name}-lb"
        namespace = kubernetes_namespace.app.metadata[0].name
            annotations = {
                "kubernetes.io/ingress.class" = "alb",
                "alb.ingress.kubernetes.io/scheme" = "internet-facing",
                "alb.ingress.kubernetes.io/target-type" = "ip"
                "alb.ingress.kubernetes.io/certificate-arn" =  var.cert_arn
                "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
                "alb.ingress.kubernetes.io/ssl-redirect" =  "443"
                "alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
            }
    }
    spec {
        rule {
            http {
                path {
                    path = "/*"
                    backend {
                        service {
                            name = kubernetes_service.app-nodeport.metadata.0.name
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_ingress_v1" "app2-alb" {
    wait_for_load_balancer = true
    metadata {
        name      = "${var.app_name2}-lb"
        namespace = kubernetes_namespace.app.metadata[0].name
            annotations = {
                "kubernetes.io/ingress.class" = "alb",
                "alb.ingress.kubernetes.io/scheme" = "internet-facing",
                "alb.ingress.kubernetes.io/target-type" = "ip"
                "alb.ingress.kubernetes.io/certificate-arn" =  var.cert_arn
                "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
                "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
                "alb.ingress.kubernetes.io/ssl-redirect" =  "443"
                "alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
            }
    }
    spec {
        rule {
            http {
                path {
                    path = "/*"
                    backend {
                        service {
                            name = kubernetes_service.app2-nodeport.metadata.0.name
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }
    }
}

### Horizontal Autoscaler ###

resource "kubernetes_horizontal_pod_autoscaler" "app-hpa" {
    metadata {
        name = "${var.app_name}-hpa"
        namespace = var.app_name
    }

    spec {
        max_replicas = 10
        min_replicas = 1

        scale_target_ref {
            kind = "Deployment"
            name = var.app_name
            api_version = "apps/v1"
        }
    }
}

resource "kubernetes_horizontal_pod_autoscaler" "app2-hpa" {
    metadata {
        name = "${var.app_name2}-hpa"
        namespace = var.app_name
    }

    spec {
        max_replicas = 10
        min_replicas = 1

        scale_target_ref {
            kind = "Deployment"
            name = var.app_name2
            api_version = "apps/v1"
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