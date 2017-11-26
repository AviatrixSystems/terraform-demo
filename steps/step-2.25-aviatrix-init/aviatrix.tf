/* set the admin email */
resource "aviatrix_admin_email" "admin_email" {
    provider = "aviatrix.demo"
    admin_email = "${local.aviatrix_admin_email}"
}

/* set admin password */
resource "null_resource" "set_admin_password" {
    provisioner "local-exec" {
        command = "curl -v --insecure 'https://${local.aviatrix_controller_ip}/v1/backend1' --data 'action=user_login_management&subaction=change_password&user_name=admin&account_name=admin&old_password=${local.aviatrix_controller_private_ip}&password=${local.aviatrix_password}&confirm_password=${local.aviatrix_password}&CID=${data.aviatrix_caller_identity.demo.cid}' | grep -vi 'Invalid Session'"
    }
    depends_on= [ "aviatrix_admin_email.admin_email" ]
}
