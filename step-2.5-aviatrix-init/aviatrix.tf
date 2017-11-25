provider "aviatrix" {
    alias = "demo"
    username = "admin"
    password = "${local.aviatrix_password}"
    controller_ip = "${local.aviatrix_controller_ip}"
}
data "aviatrix_caller_identity" "current" {
    provider = "aviatrix.demo"
}

/* aviatrix account */
data "aviatrix_account" "controller_demo" {
    provider = "aviatrix.demo"
    account_name = "${local.aviatrix_account_name}"
}

/* set the customer id (license key) */
resource "aviatrix_customer_id" "customer_id" {
    provider = "aviatrix.demo"
    customer_id = "${var.aviatrix_customer_id}"
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
        "data.aws_cloudformation_stack.controller_quickstart" ]
}

/* reset admin password */
resource "null_resource" "set_admin_password" {
    provisioner "local-exec" {
        when = "destroy"
        command = "curl -v --insecure 'https://${local.aviatrix_controller_ip}/v1/backend1' --data 'action=user_login_management&subaction=change_password&user_name=admin&account_name=admin&old_password=P@ssw0rd!&password=${local.aviatrix_controller_private_ip}&confirm_password=${local.aviatrix_controller_private_ip}&CID=${data.aviatrix_caller_identity.current.cid}' | grep -vi 'Invalid Session'"
    }
}
