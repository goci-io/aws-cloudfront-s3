module "cdn_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  environment = var.environment
  namespace   = var.namespace
  name        = var.name
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
  aliases             = concat([var.dns_zone_name], var.cloudfront_aliases)
  comment             = var.cloudfront_comment
  default_root_object = var.cloudfront_default_root
  price_class         = var.cloudfront_price_class
  tags                = module.cdn_label.tags

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
    cached_methods         = ["GET", "HEAD"]
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = local.s3_origin_id
    min_ttl                = var.cloudfront_min_ttl
    max_ttl                = var.cloudfront_max_ttl
    default_ttl            = var.cloudfront_default_ttl
    viewer_protocol_policy = var.cloudfront_viewer_protocol_policy
    trusted_signers        = [data.aws_caller_identity.current.account_id]

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
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
