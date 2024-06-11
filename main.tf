################################################################################
# Cloudfront
################################################################################

locals {
  cf_function_path      = format("%s/%s", path.module, coalesce(var.custom_cf_function, "cloudfront_function.js"))       # If var.custom_cf_function is empty, use the default cloudfront_function.js
  cloudfront_function   = file(local.cf_function_path)                                                                   # Grab the cloudfront function
  cloudfront_functionV1 = replace(local.cloudfront_function, "{destination}", var.destination)                           # Define the var destination, where the redirect should go.
  cloudfront_functionV2 = replace(local.cloudfront_functionV1, "{is_static_redirect}", tostring(var.is_static_redirect)) # Define the var isStaticRedirect, if we keep the path when redirecting.
  cloudfront_comment    = substr("CloudFront distribution for redirecting ${var.domain} to ${var.destination}.", 0, 128) # Comments can only be 128 chars long
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    connection_attempts = 1
    connection_timeout  = 1
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    domain_name = "dummy.test"
    origin_id   = "dummy"
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = local.cloudfront_comment
  aliases         = [var.domain]

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET", "OPTIONS"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    target_origin_id       = "dummy"
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = false


    forwarded_values {
      # Forward the protocol header so we can redirect using the same protocol
      headers      = ["CloudFront-Forwarded-Proto"]
      query_string = true
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_cloudfront_function.redirect]
}

resource "random_string" "aws_cloudfront_function_id" {
  length  = 8
  special = false
  lower   = false
}

resource "aws_cloudfront_function" "redirect" {
  name    = "redirect_${random_string.aws_cloudfront_function_id.result}"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect all requests"
  publish = true
  code    = local.cloudfront_functionV2
}

################################################################################
# SSL Cert
################################################################################

resource "aws_acm_certificate" "cloudfront" {
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# DNS
################################################################################

resource "aws_route53_record" "cloudfront" {
  zone_id         = var.route53_zone_id
  name            = var.domain
  type            = "A"
  allow_overwrite = false

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_ipv6" {
  zone_id         = var.route53_zone_id
  name            = var.domain
  type            = "AAAA"
  allow_overwrite = false

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = var.route53_zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "cloudfront" {
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
