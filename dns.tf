locals {
  unique_zone_names = var.dns_zone_name == "" ? [] : concat([var.dns_zone_name], distinct(values(var.cloudfront_aliases)))
  domain_name       = var.cloudfront_domain == "" ? var.dns_zone_name : format("%s.%s", var.cloudfront_domain, var.dns_zone_name)
}

data "aws_route53_zone" "zones" {
  count = length(local.unique_zone_names)
  name  = element(local.unique_zone_names, count.index)
}

locals {
  trimmed_zone_names = [for zone in data.aws_route53_zone.zones : trimsuffix(zone.name, ".")]
  zone_to_id         = zipmap(local.trimmed_zone_names, data.aws_route53_zone.zones.*.zone_id)
}

resource "aws_acm_certificate" "cloudfront" {
  provider                  = aws.us-east
  count                     = var.dns_zone_name == "" ? 0 : 1
  domain_name               = local.domain_name
  validation_method         = "DNS"
  tags                      = module.cdn_label.tags
  subject_alternative_names = keys(var.cloudfront_aliases)

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  record_to_zone_name = merge({ "${local.domain_name}" = var.dns_zone_name }, var.cloudfront_aliases)
  validation_options  = length(aws_acm_certificate.cloudfront.*.domain_validation_options) > 0 ? aws_acm_certificate.cloudfront[0].domain_validation_options : []
  validations_map = [for validation in local.validation_options : {
    name  = validation.resource_record_name
    type  = validation.resource_record_type
    value = validation.value

    # 1. Get Zone By Record Name (without Validation Prefix, <validation>.my.record.io becomes my.record.io)
    # 2. Trimsuffix is to cut off potential trailing Dots (validation record names might contain some)
    # 3. Finally map Zone Name to corresponding Zone ID
    zone = local.zone_to_id[
      local.record_to_zone_name[
        trimsuffix(join(".", slice(split(".", validation.resource_record_name), 1, length(split(".", validation.resource_record_name)))), ".")
      ]
    ]
  }]
}

resource "aws_route53_record" "cloudfront_acm_validation" {
  count           = var.dns_zone_name == "" ? 0 : length(var.cloudfront_aliases) + 1
  allow_overwrite = true
  ttl             = 300
  zone_id         = local.validations_map[count.index].zone
  name            = local.validations_map[count.index].name
  type            = local.validations_map[count.index].type
  records         = [local.validations_map[count.index].value]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us-east
  count                   = var.dns_zone_name == "" ? 0 : 1
  certificate_arn         = join("", aws_acm_certificate.cloudfront.*.arn)
  validation_record_fqdns = aws_route53_record.cloudfront_acm_validation.*.fqdn
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
