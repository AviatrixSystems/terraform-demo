/* aws top level */
data "aws_caller_identity" "current" {
}
data "aws_region" "current" {
    current = true
}

/* aws cloud formation */
data "aws_cloudformation_stack" "controller_quickstart" {
    name = "aviatrix-controller"
}

/* local variables for public/private ip of controller */
locals {
    aviatrix_account_name = "demoteam"
    aviatrix_password = "P@ssw0rd!"

    aviatrix_controller_ip = "${data.aws_cloudformation_stack.controller_quickstart.outputs["AviatrixControllerEIP"]}"
    aviatrix_controller_private_ip = "${data.aws_cloudformation_stack.controller_quickstart.outputs["AviatrixControllerPrivateIP"]}"
}
