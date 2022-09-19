terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.31"
    }
		vault = {
      source = "hashicorp/vault"
      version = "~> 3.8"
    }
  }
}

provider "aws" {
  default_tags {
		tags = {
			owner       = var.owner
			se-region   = var.se-region
			purpose     = var.purpose
			ttl         = var.ttl
			terraform   = var.terraform
			hc-internet-facing = var.hc-internet-facing
	 }
	}
}
