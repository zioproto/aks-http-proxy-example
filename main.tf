locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
echo "Execute your super awesome commands here!"
sudo sed -i "s/#Port 22/Port 2222/" /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo apt-get update
sudo apt-get -y install tinyproxy
sudo sed -i "s/#Allow 10.0.0.0\/8/Allow 10.0.0.0\/8/" /etc/tinyproxy/tinyproxy.conf
sudo systemctl restart tinyproxy
CUSTOM_DATA
}

resource "azurerm_resource_group" "this" {
  name     = "aks-proxy-example"
  location = "West Europe"
}

resource "azurerm_virtual_machine" "main" {
  name                  = "myubuntuvm"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "azureuser"
    #admin_password = "Password1234!"
    custom_data = base64encode(local.custom_data)
  }



  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = var.public_ssh_key
    }
  }

}

# AKS cluster

module "aks" {
  depends_on = [azurerm_resource_group.this]

  source                     = "Azure/aks/azurerm"
  version                    = "7.6.0"
  resource_group_name        = azurerm_resource_group.this.name
  prefix                     = "myakscluster"
  network_plugin             = "azure"
  vnet_subnet_id             = azurerm_subnet.internal.id
  net_profile_dns_service_ip = "192.168.0.5"
  net_profile_service_cidr   = "192.168.0.0/16"
  rbac_aad                   = false

  http_proxy_config = {
    http_proxy = local.proxy_ip
    no_proxy   = toset(["localhost", "127.0.0.1", "10.0.0.0/8"])
  }

  agents_size = "Standard_DS3_v2"
}



# use nic private IP for proxy address
locals {
  proxy_ip = "http://${azurerm_network_interface.main.private_ip_address}:8888/"

}
