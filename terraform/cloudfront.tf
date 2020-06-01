# Lookup certificate to use ARN later on
/*data "aws_acm_certificate" "wellcomecollection_ssl_cert" {
  domain = "wellcomecollection.org"
}*/

# If you use the lookup above, you get an error from Terraform:
#
#     Error: Multiple certificates for domain "wellcomecollection.org" found
#     in this region
#
# For now I've hard-coded the ARN that was already in use, but long-term we
# should probably fix the certificates so we can use the data block again.
locals {
  acm_certificate_arn = "arn:aws:acm:us-east-1:130871440101:certificate/9b4d357e-689f-4fd3-bf12-4e6c5fd4af35"
}

resource "aws_cloudfront_distribution" "wellcomeimages" {
  origin {
    domain_name = "wellcomeimages.org"
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
        "MIRO",    # Wellcome Images redirect
        "MIROPAC", # Wellcome Images redirect
        "query",
      ]

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.edge_lambda_request.qualified_arn
    }
  }

  viewer_certificate {
    acm_certificate_arn      = local.acm_certificate_arn
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
