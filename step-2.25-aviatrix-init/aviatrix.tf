/* aviatrix object (to get CID) */
provider "aviatrix" {
    alias = "demoprep"
    username = "admin"
    password = "${local.aviatrix_controller_private_ip}"
    controller_ip = "${local.aviatrix_controller_ip}"
}
data "aviatrix_caller_identity" "current" {
    provider = "aviatrix.demoprep"
}

/* set the admin email */
resource "aviatrix_admin_email" "admin_email" {
    provider = "aviatrix.demoprep"
    admin_email = "${var.aviatrix_admin_email}"
}

/* upgrade controller to latest version */
resource "null_resource" "set_admin_password" {
    provisioner "local-exec" {
        command = "curl -v --insecure 'https://${local.aviatrix_controller_ip}/v1/backend1' --data 'action=user_login_management&subaction=change_password&user_name=admin&account_name=admin&old_password=${local.aviatrix_controller_private_ip}&password=P@ssw0rd!&confirm_password=P@ssw0rd!&CID=${data.aviatrix_caller_identity.current.cid}' | grep -vi 'Invalid Session'"
    }
}
