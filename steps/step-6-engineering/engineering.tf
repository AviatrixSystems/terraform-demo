/* aviatrix account */
data "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "${local.aviatrix_account_name}"
}

module "engineering-1" {
    source = "../../modules/spoke"
    spoke_name = "engineering-1"
    spoke_cidr_block = "172.16.128.0/20"
    spoke_public_net_cidr_block = "172.16.129.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "ca-central-1"
    gw_name_transit = "${local.gw_name_transit}"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

/* aviatrix engineering-1 to onprem through transit */
resource "aviatrix_transpeer" "engineering_to_onprem" {
    provider = "aviatrix.demo"
    source = "${module.engineering-1.spoke_gw_name}"
    nexthop = "${local.gw_name_transit}"
    reachable_cidr = "10.0.0.0/16"
}
