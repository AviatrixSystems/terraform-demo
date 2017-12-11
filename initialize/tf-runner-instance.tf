provider "aws" {
    alias      = "setup"
    region     = "us-west-2"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

/* key pair */
resource "aws_key_pair" "demo_key" {
    provider = "aws.setup"
    key_name = "aviatrix-demo"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwgE2GMY96R10W4Pe4mUvp24U+ZgJZRBfG0Oil3VYOIophKxkjYoY8yA2q+a9NtENTucDfa03hq+y68NahvtDAYO3MkujXobi/dZLn8AYPQxMjfENNAhPrOv/RvA3hHV2rxktmaaQnnNaySa34XUUJ5hENfD8ss178BelA3Xqv2w1f/MiYNF3D1EPag/ricwreyWYldQdeAnd8h/jMdO0WOKfZ+sUP0jslqMP20T4DcigeKVdcXuVtkg+Aco3lO/tTBuXwF9B1i40/+mkMFcUA348ZdUZUo0MUZhRyvvEGYikIRr2klsqvtnBmx+jz75UAZDTJ5VGpCVBZu7KsEckd"
}

/* look up the default vpc */
resource "aws_default_vpc" "default" {
    provider = "aws.setup"
}
resource "aws_default_subnet" "default" {
    provider = "aws.setup"
    availability_zone = "us-west-2a"
    depends_on = [ "aws_default_vpc.default" ]
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
    ]
}
resource "aws_instance" "runner" {
    provider = "aws.setup"
    ami = "ami-0def3275"
    associate_public_ip_address = true
    instance_type = "t2.small"
    key_name = "aviatrix-demo"
    vpc_security_group_ids = [ "${aws_security_group.runner.id}" ]
    subnet_id = "${aws_default_subnet.default.id}"
    tags {
        Name = "main"
    }
    depends_on = [ "aws_security_group.runner",
        "aws_key_pair.demo_key",
        "aws_default_subnet.default" ]
}
resource "aws_eip" "runner" {
    provider = "aws.setup"
    instance = "${aws_instance.runner.id}"
    vpc = true
    depends_on = [ "aws_instance.runner" ]
}

resource "aws_route53_record" "runner" {
    provider = "aws.route53"
    name = "${local.username}.demo"
    type = "A"
    ttl = 300
    zone_id = "${data.aws_route53_zone.aviatrix_live.zone_id}"
    records = [ "${aws_eip.runner.public_ip}" ]
    depends_on = [ "data.aws_route53_zone.aviatrix_live",
        "aws_eip.runner",
        "aws_instance.runner" ]
    
}
