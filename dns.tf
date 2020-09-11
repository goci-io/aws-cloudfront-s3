locals {
  all_zones = var.dns_zone_name == "" ? [] : concat(
    var.acm_subject_alternative_dns,
    [{ name = var.cloudfront_domain, zone = var.dns_zone_name }]
  )

  domain_name = var.cloudfront_domain == "" ? var.dns_zone_name : format("%s.%s", var.cloudfront_domain, var.dns_zone_name)
}


data "aws_route53_zone" "zones" {
  count = length(local.all_zones)
  name  = element(local.all_zones.*.zone, count.index)
}

resource "aws_route53_record" "cloudfront_acm_validation" {
  count           = length(local.all_zones)
  zone_id         = data.null_data_source.dns_validations[count.index].outputs.zone
  allow_overwrite = true
  ttl             = 300
  name            = data.null_data_source.dns_validations[count.index].outputs.name
  type            = data.null_data_source.dns_validations[count.index].outputs.type
  records         = [data.null_data_source.dns_validations[count.index].outputs.value]
}

module "cdn_dns" {
  source      = "git::https://github.com/goci-io/aws-route53-records.git?ref=tags/0.4.1"
  enabled     = var.dns_zone_name != ""
  hosted_zone = var.dns_zone_name
  alias_records = concat(
    [{
      name       = var.cloudfront_domain
      alias      = aws_cloudfront_distribution.cdn.domain_name
      alias_zone = aws_cloudfront_distribution.cdn.hosted_zone_id
    }],
    [for alias in var.cloudfront_aliases : {
      name       = alias
      alias      = aws_cloudfront_distribution.cdn.domain_name
      alias_zone = aws_cloudfront_distribution.cdn.hosted_zone_id
    }]
  )
}
