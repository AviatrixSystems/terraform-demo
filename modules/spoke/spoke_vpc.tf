/*
 * This builds a spoke and related components.
 */

variable "spoke_cidr_block" {
    type = "string"
    default = ""
}
variable "spoke_public_net_cidr_block" {
    type = "string"
    default = ""
}
variable "spoke_name" {
    type = "string"
    default = ""
}
variable "spoke_controller_account" {
    type = "string"
    default = ""
}
variable "spoke_region" {
    type = "string"
    default = ""
}
variable "aws_access_key" {
    type = "string"
    default = ""
}
variable "aws_secret_key" {
    type = "string"
    default = ""
}

provider "aws" {
    alias      = "spoke"
    region     = "${var.spoke_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

/* AWS vpc, subnet, igw, route table */
resource "aws_vpc" "spoke" {
    provider = "aws.spoke"
    cidr_block = "${var.spoke_cidr_block}"
    tags {
        "Name" = "${var.spoke_name}"
    }
}

resource "aws_subnet" "public_net_spoke" {
    provider = "aws.spoke"
    vpc_id = "${aws_vpc.spoke.id}"
    tags {
        "Name" = "public_net_${var.spoke_name}"
    }
    cidr_block = "${var.spoke_public_net_cidr_block}"
    depends_on = [ "aws_vpc.spoke" ]
}

resource "aws_internet_gateway" "igw_spoke" {
    provider = "aws.spoke"
    vpc_id = "${aws_vpc.spoke.id}"
    tags = {
        Name = "igw_${var.spoke_name}"
    }
    depends_on = [ "aws_vpc.spoke" ]
}

resource "aws_route_table" "rt_public_net_spoke" {
    provider = "aws.spoke"
    depends_on = [ "aws_vpc.spoke" ]
    vpc_id = "${aws_vpc.spoke.id}"
}

resource "aws_route_table_association" "spoke_rt_to_public_subnet" {
    provider = "aws.spoke"
    subnet_id = "${aws_subnet.public_net_spoke.id}"
    route_table_id = "${aws_route_table.rt_public_net_spoke.id}"
    depends_on = [ "aws_subnet.public_net_spoke",
        "aws_route_table.rt_public_net_spoke" ]
}

resource "aws_route" "route_public_net_spoke" {
    provider = "aws.spoke"
    route_table_id = "${aws_route_table.rt_public_net_spoke.id}"
    gateway_id = "${aws_internet_gateway.igw_spoke.id}"
    depends_on = [ "aws_internet_gateway.igw_spoke",
        "aws_route_table.rt_public_net_spoke" ]
    destination_cidr_block = "0.0.0.0/0"
}

/* aviatrix gateway */
resource "aviatrix_gateway" "spoke" {
    provider = "aviatrix.demo"
    cloud_type = "1"
    account_name = "${var.spoke_controller_account}"
    gw_name = "gw-${var.spoke_name}"
    vpc_id = "${aws_vpc.spoke.id}~~${var.spoke_name}"
    vpc_reg = "${var.spoke_region}"
    vpc_size = "t2.small"
    vpc_net = "${var.spoke_public_net_cidr_block}"
    depends_on = [ "aws_vpc.spoke",
        "aws_subnet.public_net_spoke",
        "aws_internet_gateway.igw_spoke",
        "aws_route.route_public_net_spoke" ]
}

/* aviatrix tunnel to service */
resource "aviatrix_tunnel" "spoke_to_transit" {
    provider = "aviatrix.demo"
    vpc_name1 = "gw-${var.spoke_name}"
    vpc_name2 = "gw-service-hub"
    over_aws_peering = "no"
    peering_hastatus = "disabled"
    cluster = "no"
    depends_on = [ "aviatrix_gateway.spoke" ]
}

/* aviatrix tunnel to transit */
resource "aviatrix_tunnel" "spoke_to_service" {
    provider = "aviatrix.demo"
    vpc_name1 = "gw-transit-hub"
    vpc_name2 = "gw-${var.spoke_name}"
    over_aws_peering = "no"
    peering_hastatus = "disabled"
    cluster = "no"
    depends_on = [ "aviatrix_gateway.spoke" ]
}

output "spoke_vpc_id" {
    value = "${aws_vpc.spoke.id}"
}

output "spoke_gw_name" {
    value = "gw-${var.spoke_name}"
}
