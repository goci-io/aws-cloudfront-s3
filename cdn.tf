module "cdn_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  environment = var.environment
  namespace   = var.namespace
  name        = var.name
  stage       = var.stage
  attributes  = var.attributes
  tags        = var.tags
}

locals {
  s3_origin_id = format("%sDefaultOrigin", title(var.name))
}

resource "random_uuid" "s3_restriction_key" {}

resource "aws_cloudfront_origin_access_identity" "signer" {
  comment = module.cdn_label.id
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.cloudfront_comment
  default_root_object = var.cloudfront_default_root
  price_class         = var.cloudfront_price_class
  tags                = module.cdn_label.tags
  aliases             = var.dns_zone_name == "" ? [] : concat([local.domain_name], keys(var.cloudfront_aliases))

  origin {
    domain_name = aws_s3_bucket.content.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    custom_header {
      name  = "User-Agent"
      value = random_uuid.s3_restriction_key.result
    }

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.signer.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    cached_methods         = var.cloudfront_cached_methods
    allowed_methods        = var.cloudfront_allowed_methods
    target_origin_id       = local.s3_origin_id
    min_ttl                = var.cloudfront_min_ttl
    max_ttl                = var.cloudfront_max_ttl
    default_ttl            = var.cloudfront_default_ttl
    trusted_signers        = var.cloudfront_trusted_signers
    viewer_protocol_policy = var.cloudfront_viewer_protocol_policy

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.dns_zone_name == "" ? [] : [1]

    content {
      acm_certificate_arn = join("", aws_acm_certificate_validation.cloudfront.*.certificate_arn)
      ssl_support_method  = "sni-only"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.dns_zone_name == "" ? [1] : []

    content {
      cloudfront_default_certificate = true
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "custom_error_response" {
    for_each = var.cloudfront_404_rewrite == "" ? [] : [1]

    content {
      error_code         = "404"
      response_code      = var.cloudfront_404_rewrite_code
      response_page_path = var.cloudfront_404_rewrite
    }
  }
}

resource "aws_cloudfront_public_key" "signing" {
  count       = length(var.cloudfront_public_keys)
  comment     = module.cdn_label.id
  name        = format("%s-%d", module.cdn_label.id, count.index)
  encoded_key = var.cloudfront_public_keys[count.index]
}
