/* upgrade controller to latest version */
resource "null_resource" "upgrade_controller" {
    provisioner "local-exec" {
        command = "curl -v --insecure 'https://${local.aviatrix_controller_ip}/v1/backend1' --data 'action=userconnect_release&CID=${data.aviatrix_caller_identity.demo.cid}'"
    }
}
