# aws-cloudfront-s3

**Maintained by [@goci-io/prp-terraform](https://github.com/orgs/goci-io/teams/prp-terraform)**

Repository created by [goci-io/github-repository](https://github.com/goci-io/github-repository)

### Usage

```hcl
module "cloudfront" {
  source    = "git::https://github.com/goci-io/aws-cloudfront-s3.git?ref=tags/<latest-version>"
  namespace = "goci"
  name      = "cdn"
}
```

_This repository was created via [github-repository](https://github.com/goci-io/github-repository)._
