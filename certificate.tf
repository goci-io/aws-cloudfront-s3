resource "aws_acm_certificate" "cloudfront" {
  provider                  = aws.us-east
  domain_name               = var.cloudfront_domain == "" ? var.dns_zone_name : format("%s.%s", var.cloudfront_domain, var.dns_zone_name)
  validation_method         = "DNS"
  tags                      = module.cdn_label.tags
  subject_alternative_names = var.acm_subject_alternative_dns.*.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us-east
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = aws_route53_record.cloudfront_acm_validation.*.fqdn
}
