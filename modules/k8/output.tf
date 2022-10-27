# Display load balancer hostname (typically present in AWS)
output "grafana_load_balancer_hostname" {
  value = kubernetes_ingress_v1.grafana-alb.status.0.load_balancer.0.ingress.0.hostname
}

# Display load balancer IP (typically present in GCP, or using Nginx ingress controller)
output "grafana_load_balancer_ip" {
  value = kubernetes_ingress_v1.grafana-alb.status.0.load_balancer.0.ingress.0.ip
}


# output "app_lb_hostname" {
#   value = kubernetes_service.app-lb.status.0.load_balancer.0.ingress.0.hostname
# }