output "sshlogin" {
  value = "ssh -l azureuser -p 2222 ${azurerm_public_ip.public_ip.ip_address}"
}

output "akscredentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.aks_name}"
}