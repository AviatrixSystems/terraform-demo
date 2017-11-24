/*
 * This builds the transit hub VPC and related components.
 */

/* AWS vpc, subnet, igw, route table */
resource "aws_vpc" "transit_hub" {
    cidr_block = "10.10.0.0/16"
    tags {
        "Name" = "transit_hub"
    }
}

resource "aws_subnet" "public_net_transit_hub" {
    vpc_id = "${aws_vpc.transit_hub.id}"
    tags {
        "Name" = "public_net_transit_hub"
    }
    cidr_block = "10.10.100.0/24"
    depends_on = [ "aws_vpc.transit_hub" ]
}

resource "aws_internet_gateway" "igw_transit_hub" {
    vpc_id = "${aws_vpc.transit_hub.id}"
    tags = {
        Name = "igw_transit_hub"
    }
    depends_on = [ "aws_vpc.transit_hub" ]
}

resource "aws_route_table" "rt_public_net_transit_hub" {
    depends_on = [ "aws_vpc.transit_hub" ]
    vpc_id = "${aws_vpc.transit_hub.id}"
}

resource "aws_route_table_association" "transit_hub_rt_to_public_subnet" {
    subnet_id = "${aws_subnet.public_net_transit_hub.id}"
    route_table_id = "${aws_route_table.rt_public_net_transit_hub.id}"
    depends_on = [ "aws_subnet.public_net_transit_hub",
        "aws_route_table.rt_public_net_transit_hub" ]
}

resource "aws_route" "route_public_net_transit_hub" {
    route_table_id = "${aws_route_table.rt_public_net_transit_hub.id}"
    gateway_id = "${aws_internet_gateway.igw_transit_hub.id}"
    depends_on = [ "aws_internet_gateway.igw_transit_hub",
        "aws_route_table.rt_public_net_transit_hub" ]
    destination_cidr_block = "0.0.0.0/0"
}

/* aviatrix gateway: transit */
resource "aviatrix_gateway" "transit_hub" {
    provider = "aviatrix.demo"
    cloud_type = "1"
    account_name = "${data.aviatrix_account.controller_demo.account_name}"
    gw_name = "gw-transit-hub"
    vpc_id = "${aws_vpc.transit_hub.id}"
    vpc_reg = "${data.aws_region.current.name}"
    vpc_size = "t2.small"
    vpc_net = "${aws_subnet.public_net_transit_hub.cidr_block}"
    depends_on = [ "aws_vpc.transit_hub",
        "aws_internet_gateway.igw_transit_hub",
        "aws_subnet.public_net_transit_hub",
        "aws_route.route_public_net_transit_hub",
        "data.aviatrix_account.controller_demo" ]
}
