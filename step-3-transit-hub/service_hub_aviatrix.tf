provider "aviatrix" {
    alias = "demo"
    username = "admin"
    password = "${local.aviatrix_password}"
    controller_ip = "${local.aviatrix_controller_ip}"
}
/* aviatrix account */
data "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "${local.aviatrix_account_name}"
}

/* aws service hub */
data "aws_vpc" "service_hub" {
    tags {
        "Name" = "service_hub"
    }
}
data "aws_subnet" "public_net_service_hub" {
    tags {
        "Name" = "public_net_service_hub"
    }
}
/* aviatrix gateway: services */
resource "aviatrix_gateway" "services_hub" {
    provider = "aviatrix.demo"
    cloud_type = "1"
    account_name = "${data.aviatrix_account.controller_demo.account_name}"
    gw_name = "gw-service-hub"
    vpc_id = "${data.aws_vpc.service_hub.id}"
    vpc_reg = "${data.aws_region.current.name}"
    vpc_size = "t2.small"
    vpc_net = "${data.aws_subnet.public_net_service_hub.cidr_block}"
    depends_on = [ "data.aws_vpc.service_hub",
        "data.aws_region.current",
        "data.aws_subnet.public_net_service_hub",
        "data.aviatrix_account.controller_demo" ]
}
