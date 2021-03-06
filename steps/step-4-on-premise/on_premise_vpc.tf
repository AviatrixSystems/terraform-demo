/*
 * This builds the on_premise hub VPC and related components.
 */

provider "aws" {
    alias      = "onprem"
    region     = "${local.region_name_onprem}"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

/* aviatrix account */
data "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "${local.aviatrix_account_name}"
}

/* lookup transit gateway */
data "aviatrix_gateway" "transit_hub" {
    provider = "aviatrix.demo"
    account_name = "${data.aviatrix_account.controller_demo.account_name}"
    gw_name = "${local.gw_name_transit}"
}

/* AWS vpc, subnet, igw, route table */
resource "aws_vpc" "on_premise" {
    provider = "aws.onprem"
    cidr_block = "10.0.0.0/16"
    tags {
        "Name" = "on_premise"
    }
}

resource "aws_subnet" "public_net_on_premise" {
    provider = "aws.onprem"
    vpc_id = "${aws_vpc.on_premise.id}"
    tags {
        "Name" = "public_net_on_premise"
    }
    cidr_block = "10.0.100.0/24"
    depends_on = [ "aws_vpc.on_premise" ]
}

resource "aws_internet_gateway" "igw_on_premise" {
    provider = "aws.onprem"
    vpc_id = "${aws_vpc.on_premise.id}"
    tags = {
        Name = "igw_on_premise"
    }
    depends_on = [ "aws_vpc.on_premise" ]
}

data "aws_route_table" "rt_public_net_on_premise" {
    provider = "aws.onprem"
    vpc_id = "${aws_vpc.on_premise.id}"
    depends_on = [ "aws_vpc.on_premise" ]
}

resource "aws_route_table_association" "on_premise_rt_to_public_subnet" {
    provider = "aws.onprem"
    subnet_id = "${aws_subnet.public_net_on_premise.id}"
    route_table_id = "${data.aws_route_table.rt_public_net_on_premise.id}"
    depends_on = [ "aws_subnet.public_net_on_premise",
        "data.aws_route_table.rt_public_net_on_premise" ]
}

resource "aws_route" "route_public_net_on_premise" {
    provider = "aws.onprem"
    route_table_id = "${data.aws_route_table.rt_public_net_on_premise.id}"
    gateway_id = "${aws_internet_gateway.igw_on_premise.id}"
    destination_cidr_block = "0.0.0.0/0"
    depends_on = [ "aws_internet_gateway.igw_on_premise",
        "data.aws_route_table.rt_public_net_on_premise" ]
}

/* aviatrix gateway: on_premise */
resource "aviatrix_gateway" "on_premise" {
    provider = "aviatrix.demo"
    cloud_type = "1"
    account_name = "${data.aviatrix_account.controller_demo.account_name}"
    gw_name = "${local.gw_name_onprem}"
    vpc_id = "${aws_vpc.on_premise.id}~~on_premise"
    vpc_reg = "${local.region_name_onprem}"
    vpc_size = "t2.small"
    vpc_net = "${aws_subnet.public_net_on_premise.cidr_block}~~${local.region_name_onprem}~~public_net_on_premise"
    depends_on = [ "aws_vpc.on_premise",
        "aws_internet_gateway.igw_on_premise",
        "aws_subnet.public_net_on_premise",
        "aws_route.route_public_net_on_premise",
        "data.aviatrix_account.controller_demo" ]
}

/* peer transit to on premise */
resource "aviatrix_tunnel" "transit_to_on_premise" {
    provider = "aviatrix.demo"
    vpc_name1 = "${local.gw_name_transit}"
    vpc_name2 = "${local.gw_name_onprem}"
    over_aws_peering = "no"
    peering_hastatus = "disabled"
    cluster = "no"
    depends_on = [ "aviatrix_gateway.on_premise",
        "data.aviatrix_gateway.transit_hub" ]
}
