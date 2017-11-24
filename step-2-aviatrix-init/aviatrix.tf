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

/* upgrade controller to latest version */
resource "null_resource" "upgrade_controller" {
    provisioner "local-exec" {
        command = "curl -v --insecure 'https://${local.aviatrix_controller_ip}/v1/backend1' --data 'action=userconnect_release&CID=${data.aviatrix_caller_identity.current.cid}'"
    }
}
