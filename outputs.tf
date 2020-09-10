output "certificate_arn" {
  value = join("", aws_acm_certificate_validation.cloudfront.*.certificate_arn)
}
