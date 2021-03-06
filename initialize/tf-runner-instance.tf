provider "aws" {
    alias      = "setup"
    region     = "us-west-2"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

variable "username" {
    type = "string"
}

/* key pair */
resource "aws_key_pair" "demo_key" {
    provider = "aws.setup"
    key_name = "aviatrix-demo"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwgE2GMY96R10W4Pe4mUvp24U+ZgJZRBfG0Oil3VYOIophKxkjYoY8yA2q+a9NtENTucDfa03hq+y68NahvtDAYO3MkujXobi/dZLn8AYPQxMjfENNAhPrOv/RvA3hHV2rxktmaaQnnNaySa34XUUJ5hENfD8ss178BelA3Xqv2w1f/MiYNF3D1EPag/ricwreyWYldQdeAnd8h/jMdO0WOKfZ+sUP0jslqMP20T4DcigeKVdcXuVtkg+Aco3lO/tTBuXwF9B1i40/+mkMFcUA348ZdUZUo0MUZhRyvvEGYikIRr2klsqvtnBmx+jz75UAZDTJ5VGpCVBZu7KsEckd"
}

resource "aws_vpc" "demo" {
    provider = "aws.setup"
    cidr_block = "192.168.96.0/20"
    tags {
        "Name" = "demo"
    }
}

resource "aws_subnet" "public_net_demo" {
    provider = "aws.setup"
    vpc_id = "${aws_vpc.demo.id}"
    tags {
        "Name" = "public_net_demo"
    }
    cidr_block = "192.168.101.0/24"
    depends_on = [ "aws_vpc.demo" ]
}

resource "aws_internet_gateway" "igw_demo" {
    provider = "aws.setup"
    vpc_id = "${aws_vpc.demo.id}"
    tags = {
        Name = "igw_demo"
    }
    depends_on = [ "aws_vpc.demo" ]
}

data "aws_route_table" "rt_public_net_demo" {
    provider = "aws.setup"
    depends_on = [ "aws_vpc.demo" ]
    vpc_id = "${aws_vpc.demo.id}"
}

resource "aws_route_table_association" "demo_rt_to_public_subnet" {
    provider = "aws.setup"
    subnet_id = "${aws_subnet.public_net_demo.id}"
    route_table_id = "${data.aws_route_table.rt_public_net_demo.id}"
    depends_on = [ "aws_subnet.public_net_demo",
        "data.aws_route_table.rt_public_net_demo" ]
}

resource "aws_route" "route_public_net_demo" {
    provider = "aws.setup"
    route_table_id = "${data.aws_route_table.rt_public_net_demo.id}"
    gateway_id = "${aws_internet_gateway.igw_demo.id}"
    depends_on = [ "aws_internet_gateway.igw_demo",
        "data.aws_route_table.rt_public_net_demo" ]
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_security_group" "runner" {
    provider = "aws.setup"
    name = "runner"
    description = "Security group for Terraform runner instance"
    ingress = [
        {
            from_port = 22
            to_port = 22
            protocol = "TCP"
            cidr_blocks = [ "0.0.0.0/0" ]
        }
    ]
    egress = [
        {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = [ "0.0.0.0/0" ]
        }
    ],
    vpc_id = "${aws_vpc.demo.id}"
}

// TODO : remove hard-coded ami id
resource "aws_instance" "runner" {
    provider = "aws.setup"
    ami = "ami-0def3275"
    associate_public_ip_address = true
    instance_type = "t2.small"
    key_name = "aviatrix-demo"
    vpc_security_group_ids = [ "${aws_security_group.runner.id}" ]
    subnet_id = "${aws_subnet.public_net_demo.id}"
    tags {
        Name = "main"
    }
    depends_on = [ "aws_security_group.runner",
        "aws_key_pair.demo_key",
        "aws_subnet.public_net_demo" ]
}
resource "aws_eip" "runner" {
    provider = "aws.setup"
    instance = "${aws_instance.runner.id}"
    vpc = true
    depends_on = [ "aws_instance.runner" ]
}

resource "aws_route53_record" "runner" {
    provider = "aws.route53"
    name = "demo.${local.username}"
    type = "A"
    ttl = 300
    zone_id = "${data.aws_route53_zone.aviatrix_live.zone_id}"
    records = [ "${aws_eip.runner.public_ip}" ]
    depends_on = [ "data.aws_route53_zone.aviatrix_live",
        "aws_eip.runner",
        "aws_instance.runner" ]    
}

resource "null_resource" "ssh_and_prep" {
    provisioner "local-exec" {
        command = "sleep 20; ssh -o StrictHostKeyChecking=no -i ${local.key_file_path} ubuntu@${aws_eip.runner.public_ip} 'git clone https://github.com/AviatrixSystems/terraform-demo.git aviatrix-demo && cd aviatrix-demo && scripts/install-prereq-debian.sh ${var.username}'"
    }
    depends_on = [ "aws_instance.runner" ]
}
