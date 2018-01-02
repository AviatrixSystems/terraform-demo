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

data "aws_subnet" "transit_vpc_subnet" {
    provider = "aws.transit"
    vpc_id = "${data.aws_vpc.transit.id}"
    tags {
        "Name" = "public_net_transit_hub"
    }
}

data "aws_route_table" "transit" {
    provider = "aws.transit"
    subnet_id = "${data.aws_subnet.transit_vpc_subnet.id}"
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
    depends_on = [ "module.spoke-1" ]
}

// TODO: remove hard coded ami id
resource "aws_instance" "web_server" {
    provider = "aws.spoke"
    ami = "ami-55ef662f"
    instance_type = "t2.micro"
    key_name = "${module.spoke-1.spoke_gw_name}"
    subnet_id = "${data.aws_subnet.spoke_vpc_subnet.id}"
    tags {
        "Name" = "webapp-1"
    }
    vpc_security_group_ids = [ "${aws_security_group.for_web.id}" ]
    depends_on = [ "data.aws_subnet.spoke_vpc_subnet",
        "aws_security_group.for_web",
        "module.spoke-1" ]
}

resource "aws_security_group" "for_web" {
    provider = "aws.spoke"
    name        = "web_application_servers"
    description = "Allow web application servers to talk to database"
    vpc_id      = "${module.spoke-1.spoke_vpc_id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        cidr_blocks     = ["10.0.0.0/16"]
    }
}

resource "aws_security_group" "for_db" {
    provider = "aws.onprem"
    name        = "database_servers"
    description = "Allow web application servers to talk to database"
    vpc_id      = "${data.aws_vpc.onprem.id}"

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
    }
}

resource "aws_instance" "db_server" {
    provider = "aws.onprem"
    ami = "ami-a51f27c5"
    instance_type = "t2.micro"
    key_name = "${local.gw_name_onprem}"
    subnet_id = "${data.aws_subnet.onprem_vpc_subnet.id}"
    tags {
        "Name" = "db-1-onprem"
    }
    depends_on = [ "data.aws_subnet.onprem_vpc_subnet" ]
    vpc_security_group_ids = [ "${aws_security_group.for_db.id}" ]
}

resource "null_resource" "delete_route_for_debugging" {
    provisioner "local-exec" {
        command = "export AWS_ACCESS_KEY_ID=${local.aws_access_key}; export AWS_SECRET_ACCESS_KEY=${local.aws_secret_key}; aws --region ${local.region_name_transit} ec2 delete-route --destination-cidr-block 10.0.0.0/16 --route-table-id ${data.aws_route_table.transit.id}"
    }
}
