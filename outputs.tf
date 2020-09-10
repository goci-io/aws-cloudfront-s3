output "certificate_arn" {
  value = aws_acm_certificate_validation.cloudfront.certificate_arn
}
