/* aviatrix account */
data "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "${local.aviatrix_account_name}"
}

module "spoke-1" {
    source = "../../modules/spoke"
    spoke_name = "sample-app-prod"
    spoke_cidr_block = "172.16.0.0/20"
    spoke_public_net_cidr_block = "172.16.1.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "us-east-1"
    gw_name_transit = "${local.gw_name_transit}"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

module "spoke-2" {
    source = "../../modules/spoke"
    spoke_name = "sample-app-staging"
    spoke_cidr_block = "172.16.16.0/20"
    spoke_public_net_cidr_block = "172.16.17.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "us-east-2"
    gw_name_transit = "${local.gw_name_transit}"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

module "spoke-3" {
    source = "../../modules/spoke"
    spoke_name = "sample-app-dev-mike"
    spoke_cidr_block = "172.16.32.0/20"
    spoke_public_net_cidr_block = "172.16.33.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "ca-central-1"
    gw_name_transit = "${local.gw_name_transit}"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}
