output "certificate_arn" {
  value = join("", aws_acm_certificate_validation.cloudfront.*.certificate_arn)
}

output "bucket_id" {
  value = aws_s3_bucket.content.id
}

output "cloudfront_keypair_ids" {
  value = aws_cloudfront_public_key.signing.*.id
}
