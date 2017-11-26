/* lookup transit hub vpc */
data "aws_vpc" "transit_hub" {
    tags {
        "Name" = "transit_hub"
    }
}
/* aviatrix account */
data "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "${local.aviatrix_account_name}"
}

module "spoke-1" {
    source = "../../modules/spoke"
    spoke_name = "spoke-1"
    spoke_cidr_block = "172.16.0.0/20"
    spoke_public_net_cidr_block = "172.16.1.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "us-west-1"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

module "spoke-2" {
    source = "../../modules/spoke"
    spoke_name = "spoke-2"
    spoke_cidr_block = "172.16.16.0/20"
    spoke_public_net_cidr_block = "172.16.17.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "us-east-1"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

module "spoke-3" {
    source = "../../modules/spoke"
    spoke_name = "spoke-3"
    spoke_cidr_block = "172.16.32.0/20"
    spoke_public_net_cidr_block = "172.16.33.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "us-east-2"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

module "spoke-4" {
    source = "../../modules/spoke"
    spoke_name = "spoke-4"
    spoke_cidr_block = "172.16.64.0/20"
    spoke_public_net_cidr_block = "172.16.65.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "eu-west-1"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

module "spoke-5" {
    source = "../../modules/spoke"
    spoke_name = "spoke-5"
    spoke_cidr_block = "172.16.96.0/20"
    spoke_public_net_cidr_block = "172.16.97.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "eu-west-2"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}
