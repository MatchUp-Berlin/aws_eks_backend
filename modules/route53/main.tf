resource "aws_route53_zone" "app_hosted_zone" {
  name = var.app_url
}

## need to fix hard coded zone id
resource "aws_route53_record" "app-record" {
  zone_id = aws_route53_zone.app_hosted_zone.zone_id
  name    = "app.${var.app_url}"
  type    = "A"
  alias {
    evaluate_target_health = true
    name                   = var.app_load_balancer_hostname
    zone_id                = "Z215JYRZR1TBD5"
    }
}