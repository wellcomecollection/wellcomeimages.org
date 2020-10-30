resource "aws_acm_certificate" "wellcomeimages" {
  domain_name       = "wellcomeimages.org"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.wellcomeimages.org",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "wellcomeimages" {
  provider = aws.dns

  name = "wellcomeimages.org."
}

resource "aws_route53_record" "wellcomeimages" {
  provider = aws.dns

  for_each = {
    for dvo in aws_acm_certificate.wellcomeimages.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 300
  type    = each.value.type
  zone_id = data.aws_route53_zone.wellcomeimages.zone_id
}

resource "aws_acm_certificate_validation" "wellcomeimages" {
  certificate_arn         = aws_acm_certificate.wellcomeimages.arn
  validation_record_fqdns = [for record in aws_route53_record.wellcomeimages : record.fqdn]
}
