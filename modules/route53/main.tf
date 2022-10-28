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

resource "aws_route53_record" "app2-record" {
    zone_id = aws_route53_zone.app_hosted_zone.zone_id
    name    = "${var.app_url}"
    type    = "A"
    alias {
        evaluate_target_health = true
        name                   = var.app2_load_balancer_hostname
        zone_id                = "Z215JYRZR1TBD5"
    }
}

### Certificate and Validation ###

resource "aws_acm_certificate" "app-cert" {
    domain_name               = var.app_url
    validation_method         = "DNS"
    subject_alternative_names = ["*.${var.app_url}"]

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_route53_record" "app-records" {
    for_each = {
        for dvo in aws_acm_certificate.app-cert.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            record = dvo.resource_record_value
            type   = dvo.resource_record_type
        }
    }

    allow_overwrite = true
    name            = each.value.name
    records         = [each.value.record]
    ttl             = 60
    type            = each.value.type
    zone_id         = aws_route53_zone.app_hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "app-cert-validation" {
    certificate_arn         = aws_acm_certificate.app-cert.arn
    validation_record_fqdns = [for record in aws_route53_record.app-records : record.fqdn]
}