locals {
  all_zones = concat(
    var.acm_subject_alternative_dns,
    [{ name = var.cloudfront_domain, zone = var.dns_zone_name }]
  )
}

data "aws_route53_zone" "zones" {
  count = length(local.all_zones)
  name  = element(local.all_zones.*.zone, count.index)
}

locals {
  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/8531
  zone_map = zipmap(local.all_zones.*.name, data.aws_route53_zone.zones.*.zone_id)
}

data "null_data_source" "dns_validations" {
  count = length(local.all_zones)

  inputs = {
    name  = aws_acm_certificate.cloudfront.domain_validation_options[count.index].resource_record_name
    type  = aws_acm_certificate.cloudfront.domain_validation_options[count.index].resource_record_type
    value = aws_acm_certificate.cloudfront.domain_validation_options[count.index].resource_record_value
    # See local.zone_map and workaround. Example record name:
    # _7f0f8d5d2a2d54fb723fa4c93d08f8ae.dashboard.dev.corp.eu1.goci.io. (note trailing dot)
    zone = local.zone_map[join(".", slice(split(".", aws_acm_certificate.cloudfront.domain_validation_options[count.index].resource_record_name), 1, length(split(".", aws_acm_certificate.cloudfront.domain_validation_options[count.index].resource_record_name)) - 1))]
  }
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
  hosted_zone = var.dns_zone_name
  alias_records = [
    {
      name       = var.dashboard_domain
      alias      = aws_cloudfront_distribution.cdn.domain_name
      alias_zone = aws_cloudfront_distribution.cdn.hosted_zone_id
    }
  ]
}
