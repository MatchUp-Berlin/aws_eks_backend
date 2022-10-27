resource "aws_route53_zone" "app_hosted_zone" {
  name = var.app_url
}

resource "aws_route53_record" "app-record" {
  zone_id = aws_route53_zone.app_hosted_zone.zone_id
  name    = "www.${var.app_url}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.app_load_balancer_hostname]
}