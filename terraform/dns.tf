locals {
  # Most of this block is a collection of DNS records that were in-place
  # before the platform team existed, most of which we don't actively manage.
  #
  # Many of these records may be defunct; we captured them in Terraform
  # in May 2023 so we had *a* snapshot of what these DNS records look like.
  #
  # This is for consistency with the DNS records that we do manage, and to
  # give us a bit of a safety net -- if we inadvertently blat a DNS record
  # as part of our changes, we should be able to roll it back.
  #
  # We may be able to remove these records in consultation with LS&S, if
  # we know the records are defunct.

  cname_records = {
    "wi-downloads.wellcomeimages.org" = "taurus.wellcome.ac.uk"
  }

  ns_records = [
    "ns-557.awsdns-05.net.",
    "ns-411.awsdns-51.com.",
    "ns-1025.awsdns-00.org.",
    "ns-1916.awsdns-47.co.uk.",
  ]

  soa_records = {
    "wellcomeimages.org" = "ns-557.awsdns-05.net. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  }

  txt_records = {
    "wellcomeimages.org"                                    = "_globalsign-domain-verification=1kCY4qhhGcic0AEIguR2QVLwixKmlxKqy7FgpgNcye"
    "_pki-validation.wellcomeimages.org"                    = "19FA-9346-DF91-EF98-FB22-DA70-C569-A88E"
    "_pki-validation.wellcomeimages-org.wellcomeimages.org" = "B643-4EB1-F91C-11A8-F7E0-9B2B-6255-C4F9"
  }
}

data "aws_route53_zone" "wellcomeimages" {
  provider = aws.dns

  name = "wellcomeimages.org."
}

resource "aws_route53_record" "cloudfront_domain" {
  zone_id = data.aws_route53_zone.wellcomeimages.id
  name    = "wellcomeimages.org"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.wellcomeimages.domain_name
    evaluate_target_health = false
    # This is a fixed value for CloudFront distributions, see:
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-aliastarget.html
    zone_id = "Z2FDTNDATAQYW2"
  }

  weighted_routing_policy {
    weight = 1
  }

  set_identifier = "images traffic to new site"

  provider = aws.dns
}


resource "aws_route53_record" "cloudfront_ip" {
  zone_id = data.aws_route53_zone.wellcomeimages.id
  name    = "wellcomeimages.org"
  type    = "A"

  weighted_routing_policy {
    weight = 0
  }

  records = ["195.143.129.143"]

  ttl = 300

  set_identifier = "images traffic to old site"

  provider = aws.dns
}

resource "aws_route53_record" "txt" {
  for_each = local.txt_records

  zone_id = data.aws_route53_zone.wellcomeimages.id
  name    = each.key
  type    = "TXT"
  records = [each.value]
  ttl     = 300

  provider = aws.dns
}

resource "aws_route53_record" "soa" {
  for_each = local.soa_records

  zone_id = data.aws_route53_zone.wellcomeimages.id
  name    = each.key
  type    = "SOA"
  records = [each.value]
  ttl     = 900

  provider = aws.dns
}

resource "aws_route53_record" "ns" {
  zone_id = data.aws_route53_zone.wellcomeimages.id
  name    = "wellcomeimages.org"
  type    = "NS"
  records = local.ns_records
  ttl     = 172800

  provider = aws.dns
}
