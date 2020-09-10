terraform {
  required_version = ">= 0.12.1"

  required_providers {
    aws    = "~> 2.50"
    null   = "~> 2.1"
    random = "~> 2.3"
  }
}

provider "aws" {
}

provider "aws" {
  alias = "us-east"
}

data "aws_caller_identity" "current" {}
