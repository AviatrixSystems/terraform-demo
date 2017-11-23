/*
 * This builds the on_premise hub VPC and related components.
 */

provider "aws" {
    alias      = "onprem"
    region     = "ca-centra-1"
}


/* AWS vpc, subnet, igw, route table */
resource "aws_vpc" "on_premise" {
    cidr_block = "10.0.0.0/16"
    tags {
        "Name" = "on_premise"
    }
}

resource "aws_subnet" "public_net_on_premise" {
    vpc_id = "${aws_vpc.on_premise.id}"
    tags {
        "Name" = "public_net_on_premise"
    }
    cidr_block = "10.0.100.0/24"
    depends_on = [ "aws_vpc.on_premise" ]
}

resource "aws_internet_gateway" "igw_on_premise" {
    vpc_id = "${aws_vpc.on_premise.id}"
    tags = {
        Name = "igw_on_premise"
    }
    depends_on = [ "aws_vpc.on_premise" ]
}

resource "aws_route_table" "rt_public_net_on_premise" {
    depends_on = [ "aws_vpc.on_premise" ]
    vpc_id = "${aws_vpc.on_premise.id}"
}

resource "aws_route_table_association" "on_premise_rt_to_public_subnet" {
    subnet_id = "${aws_subnet.public_net_on_premise.id}"
    route_table_id = "${aws_route_table.rt_public_net_on_premise.id}"
    depends_on = [ "aws_subnet.public_net_on_premise",
        "aws_route_table.rt_public_net_on_premise" ]
}

resource "aws_route" "route_public_net_on_premise" {
    route_table_id = "${aws_route_table.rt_public_net_on_premise.id}"
    gateway_id = "${aws_internet_gateway.igw_on_premise.id}"
    depends_on = [ "aws_internet_gateway.igw_on_premise",
        "aws_route_table.rt_public_net_on_premise" ]
    destination_cidr_block = "0.0.0.0/0"
}

/* aviatrix gateway: on_premise */
resource "aviatrix_gateway" "on_premise" {
    provider = "aviatrix.demo"
    cloud_type = "1"
    account_name = "${aviatrix_account.controller_demo.account_name}"
    gw_name = "gw-on-premise"
    vpc_id = "${aws_vpc.on_premise.id}"
    vpc_reg = "${data.aws_region.current.name}"
    vpc_size = "t2.small"
    vpc_net = "${aws_subnet.public_net_on_premise.cidr_block}"
    depends_on = [ "aws_vpc.on_premise",
        "aws_subnet.public_net_on_premise",
        "aviatrix_account.controller_demo" ]
}

/* peer transit to on premise */
resource "aviatrix_tunnel" "transit_to_on_premise" {
    provider = "aviatrix.demo"
    vpc_name1 = "gw-transit-hub"
    vpc_name2 = "gw-on-premise"
    depends_on = [ "aviatrix_gateway.on_premise" ]
}
