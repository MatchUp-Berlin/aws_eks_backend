
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

### Prometheus Helm Chart ###

resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "prometheus-community/prometheus"
  version    = "15.16.1"
  namespace  = "prometheus"
}

### Grafana Helm Chart ###

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana/grafana"
  version    = "6.42.2"
  namespace  = "prometheus"

  set {
    name  = "adminUser"
    value = var.GRAFANA_ADMIN
  }

  set {
    name  = "adminPassword"
    value = var.GRAFANA_PASSWORD
  }
}

### Load Balancer Service Deployment ###

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