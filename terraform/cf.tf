# Lookup certificate to use ARN later on
data "aws_acm_certificate" "wellcomecollection_ssl_cert" {
  domain = "wellcomecollection.org"
}

resource "aws_cloudfront_distribution" "wellcomeimages" {
  origin {
    domain_name = "wi.wellcomecollection.org"
    origin_id   = "origin"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = [
    "wellcomeimages.org",
    "*.wellcomeimages.org",
  ]

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET", "OPTIONS"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = "origin"
    min_ttl                = 86400
    default_ttl            = 86400
    max_ttl                = 86400

    forwarded_values {
      headers      = ["Host"]
      query_string = true

      query_string_cache_keys = [
        "MIROPAC", # Wellcome Images redirect
        "MIRO",    # Wellcome Images redirect
      ]

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = "${aws_lambda_function.edge_lambda_request.qualified_arn}"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${data.aws_acm_certificate.wellcomecollection_ssl_cert.arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  retain_on_delete = true
}
