/* variables passed in */
variable "aviatrix_current_password" {
    type = "string"
    default = ""
}

/* local variables */
locals {
    gw_name_transit = "gw-transit-hub"
    gw_name_onprem = "gw-on-premise"
    vpc_name_transit = "transit_hub"
    vpc_name_onprem = "on_premise"
    region_name_transit = "us-west-2"
    region_name_onprem = "us-west-1"
    region_name_services = "ca-central-1"
}

/* aws provider (services vpc) */
provider "aws" {
    alias = "services"
    region     = "${local.region_name_services}"
    access_key = "${local.aws_access_key}"
    secret_key = "${local.aws_secret_key}"
}

/* aws cloud formation */
data "aws_cloudformation_stack" "controller_quickstart" {
    provider = "aws.services"
    name = "aviatrix-controller"
}

/* local variables for public/private ip of controller */
locals {
    aviatrix_controller_ip = "${data.aws_cloudformation_stack.controller_quickstart.outputs["AviatrixControllerEIP"]}"
    aviatrix_controller_private_ip = "${data.aws_cloudformation_stack.controller_quickstart.outputs["AviatrixControllerPrivateIP"]}"
}

/* controller instance */
data "aws_instance" "controller" {
    provider = "aws.services"
    filter {
        name = "network-interface.association.public-ip"
        values = [ "${data.aws_cloudformation_stack.controller_quickstart.outputs["AviatrixControllerEIP"]}" ]
    }
}

/* aviatrix provider */
provider "aviatrix" {
    alias = "demo"
    username = "admin"
    password = "${var.aviatrix_current_password}"
    controller_ip = "${local.aviatrix_controller_ip}"
}

/* aviatrix object (to get CID) */
data "aviatrix_caller_identity" "demo" {
    provider = "aviatrix.demo"
}
