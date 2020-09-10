variable "namespace" {
  type        = string
  default     = null
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "environment" {
  type        = string
  default     = null
  description = "Environment, e.g. 'uw2', 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT'"
}

variable "stage" {
  type        = string
  default     = null
  description = "Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release'"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'storage'"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

variable "dns_zone_name" {
  type        = string
  default     = ""
  description = "Name of HostedZone to create Cloudfront Records in"
}

variable "acm_subject_alternative_dns" {
  type        = list(object({ name = string, zone = string }))
  default     = []
  description = "Record and Zone Names to create ACM Subject Alternative Names for. Required when cloudfront_aliases contains Aliases from multiple Hosted Zones"
}

variable "cloudfront_aliases" {
  type        = list(string)
  default     = []
  description = "Domain Aliases for the Cloudfront Distribution"
}

variable "cloudfront_comment" {
  type        = string
  default     = ""
  description = "Description for the Cloudfront Distribution"
}

variable "cloudfront_default_root" {
  type        = string
  default     = ""
  description = "Default Key for Cloudfront Root Domain"
}

variable "cloudfront_domain" {
  type        = string
  default     = ""
  description = "Domain for Cloudfront to use"
}

variable "cloudfront_price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "Price Class for the Cloudfront Distribution"
}

variable "cloudfront_min_ttl" {
  type        = number
  default     = 1800
  description = "Minimum Time to Life for Files in Cloudfront"
}

variable "cloudfront_max_ttl" {
  type        = number
  default     = 432000
  description = "Maximum Time to Life for Files in Cloudfront"
}

variable "cloudfront_default_ttl" {
  type        = number
  default     = 7200
  description = "Default Time to Life for Files in Cloudfront"
}

variable "cloudfront_viewer_protocol_policy" {
  type        = string
  default     = "redirect-to-https"
  description = "Viewer Protocol Policy for Cloudfront. If you plan to use Cloudfront with Signed URLs consider https-only"
}

variable "cloudfront_404_rewrite" {
  type        = string
  default     = ""
  description = "Adds a Redirect Rule to Cloudfront on 404 which internally rewrites the Request to the specified Key"
}

variable "cloudfront_404_rewrite_code" {
  type        = number
  default     = "200"
  description = "HTTP Code to return instead of 404. Only applies when cloudfront_404_redirect specifies a Key"
}

variable "cloudfront_public_keys" {
  type        = list(string)
  default     = []
  description = "Public Keys in PEM Format to upload to Cloudfront (for example for URL Signing)"
}

variable "lifecycle_expiration_rules" {
  type        = map({ prefix = string, expirationInDays = number })
  default     = {}
  description = "Expiration Lifecycle Rules for the S3 Bucket."
}
