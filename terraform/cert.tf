module "cert" {
  source = "github.com/wellcomecollection/terraform-aws-acm-certificate?ref=v1.0.0"

  domain_name = "wellcomeimages.org"

  subject_alternative_names = [
    "*.wellcomeimages.org",
  ]

  zone_id = data.aws_route53_zone.wellcomeimages.id

  providers = {
    aws.dns = aws.dns
  }
}
