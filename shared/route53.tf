provider "aws" {
    alias      = "route53"
    region     = "us-west-2"
    access_key = "AKIAIFXKULJ7DYH7ZOTQ"
    secret_key = "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"
}

data "aws_route53_zone" "aviatrix_live" {
    provider = "aws.route53"
    name = "aviatrix.live"
}
