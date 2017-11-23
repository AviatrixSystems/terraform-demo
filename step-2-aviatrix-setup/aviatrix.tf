variable "aviatrix_controller_ip" {
    type = "string"
    default = ""
}
variable "aviatrix_controller_private_ip" {
    type = "string"
    default = ""
}
provider "aviatrix" {
    alias = "demo"
    username = "admin"
    password = "P@ssw0rd!"/*"${var.aviatrix_controller_private_ip}" */
    controller_ip = "${var.aviatrix_controller_ip}"
}

/* aviatrix object (to get CID) */
data "aviatrix_caller_identity" "current" {
    provider = "aviatrix.demo"
}

/* aws top level */
data "aws_caller_identity" "current" {
}
data "aws_region" "current" {
    current = true
}

/* aws service hub */
data "aws_vpc" "service_hub" {
    tags {
        "Name" = "service_hub"
    }
}
data "aws_subnet" "public_net_service_hub" {
    tags {
        "Name" = "public_net_service_hub"
    }
}

/* aws cloud formation */
data "aws_cloudformation_stack" "controller_quickstart" {
    name = "aviatrix-controller"
}

/* upgrade controller to latest version */
resource "null_resource" "upgrade_controller" {
    provisioner "local-exec" {
        command = "curl -v --insecure 'https://${var.aviatrix_controller_ip}/v1/backend1' --data 'action=userconnect_release&CID=${data.aviatrix_caller_identity.current.cid}'"
    }
}

/* set the admin email */
resource "aviatrix_admin_email" "admin_email" {
    provider = "aviatrix.demo"
    admin_email = "${var.aviatrix_admin_email}"
    depends_on = [ "null_resource.upgrade_controller" ]
}

/* set the customer id (license key) */
resource "aviatrix_customer_id" "customer_id" {
    provider = "aviatrix.demo"
    customer_id = "${var.aviatrix_customer_id}"
    depends_on = [ "null_resource.upgrade_controller" ]
}

/* create aviatrix account to link to AWS */
resource "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "demoteam"
    account_password = "P@ssw0rd!"
    account_email = "${var.aviatrix_admin_email}"
    cloud_type = "1"
    aws_account_number = "${data.aws_caller_identity.current.account_id}"
    aws_iam = "true"
    aws_role_arn = "${data.aws_cloudformation_stack.controller_quickstart.outputs["AviatrixRoleAppARN"]}"
    aws_role_ec2 = "${data.aws_cloudformation_stack.controller_quickstart.outputs["AviatrixRoleEC2ARN"]}"
    depends_on = [ "data.aws_caller_identity.current",
        "data.aws_cloudformation_stack.controller_quickstart",
        "null_resource.upgrade_controller" ]
}

/* aviatrix gateway: services */
resource "aviatrix_gateway" "services_hub" {
    provider = "aviatrix.demo"
    cloud_type = "1"
    account_name = "${aviatrix_account.controller_demo.account_name}"
    gw_name = "gw-service-hub"
    vpc_id = "${data.aws_vpc.service_hub.id}"
    vpc_reg = "${data.aws_region.current.name}"
    vpc_size = "t2.small"
    vpc_net = "${data.aws_subnet.public_net_service_hub.cidr_block}"
    depends_on = [ "data.aws_vpc.service_hub",
        "data.aws_region.current",
        "data.aws_subnet.public_net_service_hub",
        "aviatrix_account.controller_demo",
        "null_resource.upgrade_controller" ]
}

