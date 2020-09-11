resource "aws_acm_certificate" "cloudfront" {
  provider                  = aws.us-east
  count                     = var.dns_zone_name == "" ? 0 : 1
  domain_name               = local.domain_name
  validation_method         = "DNS"
  tags                      = module.cdn_label.tags
  subject_alternative_names = var.acm_subject_alternative_dns.*.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us-east
  count                   = var.dns_zone_name == "" ? 0 : 1
  certificate_arn         = join("", aws_acm_certificate.cloudfront.*.arn)
  validation_record_fqdns = aws_route53_record.cloudfront_acm_validation.*.fqdn
}

locals {
  # Workaround for https://github.com/terraform-providers/terraform-provider-aws/issues/8531
  zone_map = zipmap(local.all_zones.*.name, data.aws_route53_zone.zones.*.zone_id)

  validation_options = length(aws_acm_certificate.cloudfront.*.domain_validation_options) > 0 ? aws_acm_certificate.cloudfront[0].domain_validation_options : []
}

data "null_data_source" "dns_validations" {
  count = length(local.all_zones)

  inputs = {
    name  = local.validation_options[count.index].resource_record_name
    type  = local.validation_options[count.index].resource_record_type
    value = local.validation_options[count.index].resource_record_value
    # See local.zone_map and workaround. Example record name:
    # _7f0f8d5d2a2d54fb723fa4c93d08f8ae.dashboard.dev.corp.eu1.goci.io. (note trailing dot)
    zone = local.zone_map[join(".", slice(split(".", local.validation_options[count.index].resource_record_name), 1, length(split(".", local.validation_options[count.index].resource_record_name)) - 1))]
  }
}
