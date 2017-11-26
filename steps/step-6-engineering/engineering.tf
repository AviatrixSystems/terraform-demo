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
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

module "engineering-2" {
    source = "../../modules/spoke"
    spoke_name = "engineering-2"
    spoke_cidr_block = "172.16.160.0/20"
    spoke_public_net_cidr_block = "172.16.161.0/28"
    spoke_controller_account = "${data.aviatrix_account.controller_demo.account_name}"
    spoke_region = "ca-central-1"
    aws_access_key = "${local.aws_access_key}"
    aws_secret_key = "${local.aws_secret_key}"
}

/* aviatrix engineering-1 to engineering-2 */
resource "aviatrix_tunnel" "engineering_to_engineering" {
    provider = "aviatrix.demo"
    vpc_name1 = "${module.engineering-1.spoke_gw_name}"
    vpc_name2 = "${module.engineering-2.spoke_gw_name}"
}
