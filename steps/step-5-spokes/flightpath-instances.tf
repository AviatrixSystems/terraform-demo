provider "aws" {
    alias      = "onprem"
    region     = "${local.region_name_onprem}"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

provider "aws" {
    alias = "transit"
    region     = "${local.region_name_transit}"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

provider "aws" {
    alias      = "spoke"
    region     = "${module.spoke-1.spoke_region_name}"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

data "aws_vpc" "transit" {
    provider = "aws.transit"
    tags {
        "Name" = "${local.vpc_name_transit}"
    }
}

data "aws_vpc" "onprem" {
    provider = "aws.onprem"
    tags {
        "Name" = "${local.vpc_name_onprem}"
    }
}

data "aws_subnet" "onprem_vpc_subnet" {
    provider = "aws.onprem"
    vpc_id = "${data.aws_vpc.onprem.id}"
    tags {
        "Name" = "public_net_on_premise"
    }
}

data "aws_subnet" "spoke_vpc_subnet" {
    provider = "aws.spoke"
    vpc_id = "${module.spoke-1.spoke_vpc_id}"
    tags {
        "Name" = "public_net_${module.spoke-1.spoke_name}"
    }
}

// TODO: remove hard coded ami id
resource "aws_instance" "debug_in_spoke" {
    provider = "aws.spoke"
    ami = "ami-55ef662f"
    instance_type = "t2.micro"
    key_name = "${module.spoke-1.spoke_gw_name}"
    subnet_id = "${data.aws_subnet.spoke_vpc_subnet.id}"
    tags {
        "Name" = "Troubleshooting instance 1"
    }
    depends_on = [ "data.aws_subnet.spoke_vpc_subnet" ]
}

resource "aws_instance" "debug_in_onprem" {
    provider = "aws.onprem"
    ami = "ami-a51f27c5"
    instance_type = "t2.micro"
    key_name = "${local.gw_name_onprem}"
    subnet_id = "${data.aws_subnet.onprem_vpc_subnet.id}"
    tags {
        "Name" = "Troubleshooting instance 2"
    }
    depends_on = [ "data.aws_subnet.onprem_vpc_subnet" ]
}
