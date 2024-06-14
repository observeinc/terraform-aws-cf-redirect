################################################################################
# Cloudfront
################################################################################

locals {
  cloudfront_comment = substr("Redirect ${var.domain} to ${var.destination}.", 0, 128) # Comments can only be 128 chars long

  cloudfront_function_template = templatefile("${path.module}/cloudfront_function.js", {
    destination        = var.destination
    is_static_redirect = var.is_static_redirect
  })

  cloudfront_function = coalesce(var.custom_cf_function, local.cloudfront_function_template)
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
  code    = local.cloudfront_function
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
