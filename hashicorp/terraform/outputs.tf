output "myIP" {
    description = "My External IP"
    value = chomp(data.http.myIP.body)
}

output "JumpBox_SSH" {
    description = "Connect to JumpBox"
    value = "ssh ${var.admin_user}@${azurerm_public_ip.jumpbox.ip_address}"
}

# output "Load_Balancer_IP" {
#     description = "Visit to Load Balancer"
#     value = "http://${azurerm_public_ip.LB.ip_address}:${azurerm_lb_rule.LBRule.frontend_port}"
# }