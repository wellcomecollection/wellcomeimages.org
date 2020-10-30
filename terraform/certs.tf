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
