resource "aws_s3_bucket" "content" {
  bucket = module.cdn_label.id
  tags   = module.cdn_label.tags
  acl    = "private"

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_expiration_rules

    content {
      enabled = true
      id      = lifecycle_rule.key
      prefix  = lifecycle_rule.value.prefix
      tags = merge(module.cdn_label.tags, {
        "Rule"      = lifecycle_rule.key
        "Retention" = format("%d Days", lifecycle_rule.value.expirationInDays)
        "Autoclean" = "true"
      })

      expiration {
        days = lifecycle_rule.value.expirationInDays
      }
    }
  }
}

data "aws_iam_policy_document" "allow_cf" {
  statement {
    sid       = "AllowCFOriginAccessToFiles"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.content.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"
      values   = [random_uuid.s3_restriction_key.result]
    }

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.signer.iam_arn]
    }
  }

  statement {
    sid       = "AllowCFOriginAccessToBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.content.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.signer.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cdn_access" {
  bucket = aws_s3_bucket.content.id
  policy = data.aws_iam_policy_document.allow_cf.json
}

#resource "aws_s3_bucket_public_access_block" "public_block" {
#  bucket                  = aws_s3_bucket.content.id
#  block_public_acls       = true
#  block_public_policy     = true
#  restrict_public_buckets = true
#}
