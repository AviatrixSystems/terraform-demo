locals {
    aviatrix_customer_id = "POPULATE"
    aws_access_key = "POPULATE"
    aws_secret_key = "POPULATE"
    aviatrix_admin_email = "POPULATE"

    aviatrix_account_name = "demoteam"
    aviatrix_password = "P@ssw0rd!"
}

/* aws provider */
provider "aws" {
    region     = "us-west-2"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

/* aws top level */
data "aws_caller_identity" "current" {
}
data "aws_region" "current" {
    current = true
}
