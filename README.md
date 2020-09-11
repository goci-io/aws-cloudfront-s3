# aws-cloudfront-s3

**Maintained by [@goci-io/prp-terraform](https://github.com/orgs/goci-io/teams/prp-terraform)**

![terraform](https://github.com/goci-io/aws-cloudfront-s3/workflows/terraform/badge.svg?branch=master)

### Usage

```hcl
module "cloudfront" {
  source    = "git::https://github.com/goci-io/aws-cloudfront-s3.git?ref=tags/<latest-version>"
  namespace = "goci"
  name      = "cdn"
}
```

#### Enable Custom Domain

```hcl
module "cloudfront" {
  ...
  dns_zone_name     = "goci.io"
  cloudfront_domain = "cdn"
}
```

This will result in a custom Domain Alias Record in Route53 `cdn.goci.io` pointing to your Cloudfront Distribution. 
Using a custom Domain automatically generates a custom ACM Certificate and Validation Records.
Using `cloudfront_aliases` supports adding multiple Aliases.

In case you are using Aliases in **different Hosted Zones** do not forget to update ACM SANs:

```hcl
module "cloudfront" {
  ...
  dns_zone_name               = "goci.io"
  cloudfront_domain           = "cdn"
  cloudfront_aliases          = ["cdn.different-zone.goci.io"]
  acm_subject_alternative_dns = [
    { name = "cdn.different-zone.goci.io", zone = "different-zone.goci.io" },
  ]
}
```

_This repository was created via [github-repository](https://github.com/goci-io/github-repository)._
