resource "aws_vpc" "service_hub" {
    cidr_block = "10.20.0.0/16"
    tags {
        "Name" = "service_hub"
    }
}

resource "aws_subnet" "public_net_service_hub" {
    vpc_id = "${aws_vpc.service_hub.id}"
    tags {
        "Name" = "public_net_service_hub"
    }
    cidr_block = "10.20.100.0/24"
    depends_on = [ "aws_vpc.service_hub" ]
}

resource "aws_internet_gateway" "igw_service_hub" {
    vpc_id = "${aws_vpc.service_hub.id}"
    tags = {
        Name = "igw_service_hub"
    }
    depends_on = [ "aws_vpc.service_hub" ]
}

resource "aws_route_table" "rt_public_net_service_hub" {
    depends_on = [ "aws_vpc.service_hub" ]
    vpc_id = "${aws_vpc.service_hub.id}"
}

resource "aws_route_table_association" "service_hub_rt_to_public_subnet" {
    subnet_id = "${aws_subnet.public_net_service_hub.id}"
    route_table_id = "${aws_route_table.rt_public_net_service_hub.id}"
    depends_on = [ "aws_subnet.public_net_service_hub",
        "aws_route_table.rt_public_net_service_hub" ]
}

resource "aws_route" "route_public_net_service_hub" {
    route_table_id = "${aws_route_table.rt_public_net_service_hub.id}"
    gateway_id = "${aws_internet_gateway.igw_service_hub.id}"
    depends_on = [ "aws_internet_gateway.igw_service_hub",
        "aws_route_table.rt_public_net_service_hub" ]
    destination_cidr_block = "0.0.0.0/0"
}

/* create a bucket to store quickstart file - TODO: need to automate
   getting latest version of this file */
resource "aws_s3_bucket" "temporary" {
    bucket = "demo-tf-temp-${lower(local.aws_access_key)}"
    acl = "private"
    tags {
        Name = "demo-tf-temp-${lower(local.aws_access_key)}"
    }
}
resource "aws_s3_bucket_object" "quickstart" {
    bucket = "demo-tf-temp-${lower(local.aws_access_key)}"
    key = "aviatrix-aws-quickstart.json"
    source = "data/aviatrix-aws-quickstart.json"
    depends_on = [ "aws_s3_bucket.temporary" ]
}

/* key pair */
resource "aws_key_pair" "demo_key" {
    key_name = "aviatrix-demo"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwgE2GMY96R10W4Pe4mUvp24U+ZgJZRBfG0Oil3VYOIophKxkjYoY8yA2q+a9NtENTucDfa03hq+y68NahvtDAYO3MkujXobi/dZLn8AYPQxMjfENNAhPrOv/RvA3hHV2rxktmaaQnnNaySa34XUUJ5hENfD8ss178BelA3Xqv2w1f/MiYNF3D1EPag/ricwreyWYldQdeAnd8h/jMdO0WOKfZ+sUP0jslqMP20T4DcigeKVdcXuVtkg+Aco3lO/tTBuXwF9B1i40/+mkMFcUA348ZdUZUo0MUZhRyvvEGYikIRr2klsqvtnBmx+jz75UAZDTJ5VGpCVBZu7KsEckd"
}

/* avtx controller, roles, etc (using quick start cloud formation stack) */
resource "aws_cloudformation_stack" "controller_quickstart" {
    name = "aviatrix-controller"
    template_url = "https://s3.amazonaws.com/demo-tf-temp-${lower(local.aws_access_key)}/aviatrix-aws-quickstart.json"
    parameters = {
        VPCParam = "${aws_vpc.service_hub.id}"
        SubnetParam = "${aws_subnet.public_net_service_hub.id}"
        KeyNameParam = "aviatrix-demo"
        IAMRoleParam = "no"
        InstanceTypeParam = "t2.large"
    }
    capabilities = [ "CAPABILITY_NAMED_IAM" ] /* to allow roles to be created */
    depends_on = [ "aws_vpc.service_hub",
        "aws_key_pair.demo_key",
        "aws_subnet.public_net_service_hub",
        "aws_s3_bucket_object.quickstart" ]
}

output "private-ip" {
    value = "${aws_cloudformation_stack.controller_quickstart.outputs["AviatrixControllerPrivateIP"]}"
}
output "public-ip" {
    value = "${aws_cloudformation_stack.controller_quickstart.outputs["AviatrixControllerEIP"]}"
}
output "iam-role-app-arn" {
    value = "${aws_cloudformation_stack.controller_quickstart.outputs["AviatrixRoleAppARN"]}"
}
output "iam-role-ec2-arn" {
    value = "${aws_cloudformation_stack.controller_quickstart.outputs["AviatrixRoleEC2ARN"]}"
}

