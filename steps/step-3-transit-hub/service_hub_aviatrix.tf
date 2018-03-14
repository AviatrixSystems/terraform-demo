/* aviatrix account */
data "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "${local.aviatrix_account_name}"
}

/* aws service hub */
data "aws_vpc" "service_hub" {
    provider="aws.services"
    tags {
        "Name" = "service_hub"
    }
}
data "aws_subnet" "public_net_service_hub" {
    provider="aws.services"
    tags {
        "Name" = "public_net_service_hub"
    }
}
/* aws top level */
data "aws_region" "services" {
    provider = "aws.services"
    current = true
}

/* aviatrix gateway: services */
resource "aviatrix_gateway" "services_hub" {
    provider = "aviatrix.demo"
    cloud_type = "1"
    account_name = "${data.aviatrix_account.controller_demo.account_name}"
    gw_name = "gw-service-hub"
    vpc_id = "${data.aws_vpc.service_hub.id}~~service_hub"
    vpc_reg = "${data.aws_region.services.name}"
    vpc_size = "t2.small"
    vpc_net = "${data.aws_subnet.public_net_service_hub.cidr_block}~~${data.aws_region.services.name}~~public_net_service_hub"
    depends_on = [ "data.aws_vpc.service_hub",
        "data.aws_region.services",
        "data.aws_subnet.public_net_service_hub",
        "data.aviatrix_account.controller_demo" ]
}

# remove the termination protection on the controller so the destroy will work
resource "null_resource" "disable_termination_protection" {
    provisioner "local-exec" {
        command = "export AWS_ACCESS_KEY_ID=${local.aws_access_key}; export AWS_SECRET_ACCESS_KEY=${local.aws_secret_key}; aws --region ${data.aws_region.services.name} ec2 modify-instance-attribute --no-disable-api-termination --instance-id ${data.aws_instance.controller.id}"
        when = "destroy"
    }
}

