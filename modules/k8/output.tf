output "grafana_lb_hostname" {
  value = kubernetes_service.grafana-lb.status.0.load_balancer.0.ingress.0.hostname
}

output "app_lb_hostname" {
  value = kubernetes_service.app-lb.status.0.load_balancer.0.ingress.0.hostname
}