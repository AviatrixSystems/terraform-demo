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
}

/* aws provider (services vpc) */
provider "aws" {
    alias = "services"
    region     = "ca-central-1"
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
