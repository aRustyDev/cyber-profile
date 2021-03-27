#==========================================================
# :TO-DO: 
#   - Figure out how to setup SSH keys through KeyVault
#   - Figure out a Key Management solution, Thinking of using the KeyVault and generating keys locally.
#   - Figure out how to create & assign Managed Identities
#   - Try adding different .ssh keys to the web-x VMs to see if connection is quicker.
#==========================================================
# Table of Contents
#==========================================================
# :Foundational Infrastructure:
#   - Resource Group
#   - Availability Sets
#   - Key Vault
#
# :Networking:
#   - VNet
#   - Subnet
#   - PublicIP
#   - Load Balancer
#   - Network Security Group
#
# :Virtual Machine - Jumpbox:
#   - NIC
#   - Keys
#     > public
#     > private
#     > certificate
#   - VM
#     > source_image_reference
#     > os_disk
#     > admin_ssh_key
#
# :Virtual Machine - Web-1:
#   - NIC
#   - Keys
#     > public
#     > private
#     > certificate
#   - VM
#     > source_image_reference
#     > os_disk
#     > admin_ssh_key
#
# :Virtual Machine - Web-2:
#   - NIC
#   - Keys
#     > public
#     > private
#     > certificate
#   - VM
#     > source_image_reference
#     > os_disk
#     > admin_ssh_key
#
# :Virtual Machine - Web-3:   #Cant be deployed on free tier
#   - NIC
#   - Keys
#     > public
#     > private
#     > certificate
#   - VM
#     > source_image_reference
#     > os_disk
#     > admin_ssh_key
#==========================================================
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.51.0"
    }
  }
}

# Configure Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false  # Only set to false when regularly rebuilding the entire Resource Group.
    }
  }
}

#==========================================================
# Base Infrastructure - The basic infrastructure needs
#==========================================================

# Define resource group
  resource "azurerm_resource_group" "RG" {
    name     = "RG"
    location = var.region
  }

# Create Availability Sets
  resource "azurerm_availability_set" "ASet" {
    name                = "${var.prefix}_AS"
    resource_group_name = azurerm_resource_group.RG.name
    location            = var.region
  }

# Define Key Vault for Secrets/Certs/Keys
  resource "azurerm_key_vault" "KV" {
    name                        = "${var.prefix}-KeyVault"
    location                    = var.region
    resource_group_name         = azurerm_resource_group.RG.name
    enabled_for_disk_encryption = true
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    soft_delete_retention_days  = 7
    purge_protection_enabled    = false

    sku_name = "standard"

    access_policy {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id

      key_permissions = [
        "backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapkey", "update", "verify", "wrapkey",
      ]

      secret_permissions = [
        "get", "backup", "delete", "list", "recover", "restore", "set", "purge",
      ]

      storage_permissions = [
        "backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update",
      ]
    }
  }

# Define Network Resources
  resource "azurerm_virtual_network" "VNet" {
    name                = "${var.prefix}_VNet"
    resource_group_name = azurerm_resource_group.RG.name
    location            = var.region
    address_space       = ["10.0.0.0/16",]
  }

  resource "azurerm_subnet" "internal" {
    name                 = "${var.prefix}_internal"
    resource_group_name  = azurerm_resource_group.RG.name
    virtual_network_name = azurerm_virtual_network.VNet.name
    address_prefixes     = ["10.0.1.0/24",]
  }

  resource "azurerm_public_ip" "jumpbox" {
    name                = "${var.prefix}_jumpbox"
    resource_group_name = azurerm_resource_group.RG.name
    location            = var.region
    allocation_method   = "Static"
    ip_version          = "IPv4"
  }

# # Define Load Balancing

#   resource "azurerm_public_ip" "LB" {
#     name                = "${var.prefix}_LB_PublicIP"
#     resource_group_name = azurerm_resource_group.RG.name
#     location            = var.region
#     allocation_method   = "Static"
#     ip_version          = "IPv4"
#     sku                 = "Standard" # Needed b/c has to match LB conf, and LB needs standard for backend pools
#   }

#   resource "azurerm_lb" "LB" {
#     name                = "${var.prefix}_LB"
#     location            = var.region
#     resource_group_name = azurerm_resource_group.RG.name
#     sku                 = "standard"

#     frontend_ip_configuration {
#       name                 = "PublicIPAddress"
#       public_ip_address_id = azurerm_public_ip.LB.id
#     }
#   }
  
#   resource "azurerm_lb_probe" "health" {
#     resource_group_name = azurerm_resource_group.RG.name
#     loadbalancer_id     = azurerm_lb.LB.id
#     name                = "Health-probe"
#     protocol            = "tcp"
#     port                = 80
#     interval_in_seconds = 5
#     number_of_probes    = 2 # The Unhealthy Threshhold (Def: 2)
#   }

#   resource "azurerm_lb_backend_address_pool" "backend" {
#     loadbalancer_id           = azurerm_lb.LB.id
#     name                      = "${var.prefix}_BackEndAddressPool"
#     # load_balancing_rules      = azurerm_lb_rule.LBRule.id
#     # backend_ip_configurations = [
#     #   "10.0.0.5", 
#     #   "10.0.0.6", 
#     # ]
#   }

#   resource "azurerm_lb_backend_address_pool_address" "web_1" {
#     name                    = "web-1"
#     backend_address_pool_id = azurerm_lb_backend_address_pool.backend.id
#     virtual_network_id      = azurerm_virtual_network.VNet.id
#     ip_address              = "10.0.1.5"
#   }

#   resource "azurerm_lb_backend_address_pool_address" "web_2" {
#     name                    = "web-2"
#     backend_address_pool_id = azurerm_lb_backend_address_pool.backend.id
#     virtual_network_id      = azurerm_virtual_network.VNet.id
#     ip_address              = "10.0.1.6"
#   }

#   resource "azurerm_lb_rule" "LBRule" {
#     resource_group_name            = azurerm_resource_group.RG.name
#     loadbalancer_id                = azurerm_lb.LB.id
#     name                           = "${var.prefix}_LBRule"
#     protocol                       = "Tcp"
#     frontend_port                  = 80
#     backend_port                   = 80
#     backend_address_pool_id        = azurerm_lb_backend_address_pool.backend.id
#     probe_id                       = azurerm_lb_probe.health.id
#     frontend_ip_configuration_name = azurerm_lb.LB.frontend_ip_configuration[0].name
#     load_distribution              = "SourceIPProtocol " # Session Persistence; Maps to 'Client IP & Protocol'
#     #disable_outbound_snat          =
#     #enable_tcp_reset               =
#   }

# Define Network Security Group
  resource "azurerm_network_security_group" "NSG" {
    name                = "${var.prefix}_NSG"
    resource_group_name = azurerm_resource_group.RG.name
    location            = var.region

    security_rule {
      name                          = "ping-fr-home"
      priority                      = 100
      direction                     = "Inbound"
      access                        = "Allow"
      protocol                      = "Tcp"
      source_port_range             = "*"
      destination_port_range        = "*"
      source_address_prefixes       = [chomp(data.http.myIP.body)]
      destination_address_prefixes  = [azurerm_public_ip.jumpbox.ip_address, ]
    }
    security_rule {
      name                       = "ssh-fr-home"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes      = [chomp(data.http.myIP.body)]
      destination_address_prefixes = [azurerm_public_ip.jumpbox.ip_address, ]
    }

    security_rule {
      name                          = "ssh-internal"
      priority                      = 120
      direction                     = "Inbound"
      access                        = "Allow"
      protocol                      = "Tcp"
      source_port_range             = "*"
      destination_port_range        = "22"
      source_address_prefixes         = azurerm_subnet.internal.address_prefixes  # Should actually be from JumpBoxIP to internal
      destination_address_prefixes    = azurerm_subnet.internal.address_prefixes
    }

    security_rule {
      name                          = "LB-web-traffic"
      priority                      = 130
      direction                     = "Inbound"
      access                        = "Allow"
      protocol                      = "Tcp"
      source_port_range             = "*"
      destination_port_range        = "80"
      source_address_prefixes       = [chomp(data.http.myIP.body)]
      destination_address_prefixes  = azurerm_subnet.internal.address_prefixes
    }
  }

#==========================================================
# Resource Infrastructure - The VMs and user level stuff
#==========================================================
### Define jumpbox ###

  resource "azurerm_network_interface" "jumpbox" {
    name                = "${var.prefix}_jumpbox_nic"
    location            = var.region
    resource_group_name  = azurerm_resource_group.RG.name

    ip_configuration {
      public_ip_address_id          = azurerm_public_ip.jumpbox.id
      name                          = "jumpbox"
      subnet_id                     = azurerm_subnet.internal.id
      private_ip_address_allocation = "Dynamic"
    }
  }

  resource "azurerm_key_vault_key" "jumpbox" {
    name         = "jumpbox-public-key"
    key_vault_id = azurerm_key_vault.KV.id
    key_type     = "RSA"
    key_size     = 2048

    key_opts = [
      "decrypt",
      "encrypt",
      "sign",
      "unwrapKey",
      "verify",
      "wrapKey",
    ]
  }

  resource "azurerm_key_vault_secret" "jumpbox" {
    name         = "jumpbox-private-key"
    key_vault_id = azurerm_key_vault.KV.id
    value        = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/jumpbox/id_rsa")
  }

  resource "azurerm_linux_virtual_machine" "jumpbox" {
    depends_on = [
      azurerm_key_vault_secret.jumpbox,
      azurerm_key_vault_key.jumpbox,
    ]
    name                  = "${var.prefix}_jumpbox"
    location              = var.region
    computer_name         = "jumpbox"
    admin_username        = var.admin_user
    admin_password        = var.admin_pass
    resource_group_name   = azurerm_resource_group.RG.name
    network_interface_ids = [azurerm_network_interface.jumpbox.id]
    size                  = "Standard_B1s"
    #availability_set_id   = 
    custom_data = filebase64("${path.module}/jump-init.sh")

    disable_password_authentication   = true  #Force Authentication by SSH Key

    source_image_reference  {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }

    os_disk {
      name                  = "${var.prefix}_OSdisk_jumpbox"
      storage_account_type  = "Premium_LRS"
      caching               = "ReadWrite"
    }

    admin_ssh_key {
      username   = var.admin_user
      public_key = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/jumpbox/id_rsa.pub")
    }
  }

#================================================
### Define web-1 ###

  resource "azurerm_network_interface" "web_1" {
    name                = "${var.prefix}-web-1-nic"
    location            = var.region
    resource_group_name = azurerm_resource_group.RG.name

    ip_configuration {
      name                          = "web_1"
      subnet_id                     = azurerm_subnet.internal.id
      private_ip_address_allocation = "Dynamic"
    }
  }

  resource "azurerm_key_vault_key" "web_1" {
    name         = "web-1-public-key"
    key_vault_id = azurerm_key_vault.KV.id
    key_type     = "RSA"
    key_size     = 2048

    key_opts = [
      "decrypt",
      "encrypt",
      "sign",
      "unwrapKey",
      "verify",
      "wrapKey",
    ]
  }

  resource "azurerm_key_vault_secret" "web_1" {
    name         = "web-1-private-key"
    key_vault_id = azurerm_key_vault.KV.id
    value        = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-1/id_rsa")
  }

  resource "azurerm_linux_virtual_machine" "web_1" {
    depends_on = [
      azurerm_key_vault_secret.web_1,
      azurerm_key_vault_key.web_1,
    ]
    name                  = "${var.prefix}-web-1"
    location              = var.region
    computer_name         = "web-1"
    admin_username        = var.admin_user
    admin_password        = var.admin_pass
    resource_group_name   = azurerm_resource_group.RG.name
    network_interface_ids = [azurerm_network_interface.web_1.id]
    size                  = "Standard_B1ms"
    availability_set_id   = azurerm_availability_set.ASet.id

    disable_password_authentication   = true  #Force Authentication by SSH Key

    source_image_reference  {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }

    os_disk {
      name                  = "${var.prefix}-OSdisk-web-1"
      storage_account_type  = "Premium_LRS"
      caching               = "ReadWrite"
    }

    admin_ssh_key {
      username   = var.admin_user
      public_key = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-1/id_rsa.pub")
    }
  }

#================================================
### Define web-2 ###

  resource "azurerm_network_interface" "web_2" {
    name                = "${var.prefix}-web-2-nic"
    location            = var.region
    resource_group_name = azurerm_resource_group.RG.name

    ip_configuration {
      name                          = "web_2"
      subnet_id                     = azurerm_subnet.internal.id
      private_ip_address_allocation = "Dynamic"
    }
  }

  resource "azurerm_key_vault_key" "web_2" {
    name         = "web-2-public-key"
    key_vault_id = azurerm_key_vault.KV.id
    key_type     = "RSA"
    key_size     = 2048

    key_opts = [
      "decrypt",
      "encrypt",
      "sign",
      "unwrapKey",
      "verify",
      "wrapKey",
    ]
  }

  resource "azurerm_key_vault_secret" "web_2" {
    name         = "web-2-private-key"
    key_vault_id = azurerm_key_vault.KV.id
    value        = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-2/id_rsa")
  }

  resource "azurerm_linux_virtual_machine" "web_2" {
    depends_on = [
      azurerm_key_vault_secret.web_2,
      azurerm_key_vault_key.web_2,
    ]
    name                  = "${var.prefix}-web-2"
    location              = var.region
    computer_name         = "web-2"
    admin_username        = var.admin_user
    admin_password        = var.admin_pass
    resource_group_name   = azurerm_resource_group.RG.name
    network_interface_ids = [azurerm_network_interface.web_2.id]
    size                  = "Standard_B1ms"
    availability_set_id   = azurerm_availability_set.ASet.id

    disable_password_authentication   = true  #Force Authentication by SSH Key

    source_image_reference  {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }

    os_disk {
      name                  = "${var.prefix}-OSdisk-web-2"
      storage_account_type  = "Premium_LRS"
      caching               = "ReadWrite"
    }

    admin_ssh_key {
      username   = var.admin_user
      public_key = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-2/id_rsa.pub")
    }
  }

#================================================
### Define web-3 ###    NOTE: Cant be deployed, will exceed regional cores quota on free tier

  # resource "azurerm_network_interface" "web_3" {
  #   name                = "${var.prefix}-web-3-nic"
  #   location            = var.region
  #   resource_group_name = azurerm_resource_group.RG.name

  #   ip_configuration {
  #     name                          = "web_3"
  #     subnet_id                     = azurerm_subnet.internal.id
  #     private_ip_address_allocation = "Dynamic"
  #   }
  # }

  # resource "azurerm_key_vault_key" "web_3" {
  #   name         = "web-3-public-key"
  #   key_vault_id = azurerm_key_vault.KV.id
  #   key_type     = "RSA"
  #   key_size     = 2048

  #   key_opts = [
  #     "decrypt",
  #     "encrypt",
  #     "sign",
  #     "unwrapKey",
  #     "verify",
  #     "wrapKey",
  #   ]
  # }

  # resource "azurerm_key_vault_secret" "web_3" {
  #   name         = "web-3-private-key"
  #   key_vault_id = azurerm_key_vault.KV.id
  #   value        = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-3/id_rsa")
  # }

  # resource "azurerm_linux_virtual_machine" "web_3" {
  #   depends_on = [
  #     azurerm_key_vault_secret.web_3,
  #     azurerm_key_vault_key.web_3,
  #   ]
  #   name                  = "${var.prefix}-web-3"
  #   location              = var.region
  #   computer_name         = "web-3"
  #   admin_username        = var.admin_user
  #   admin_password        = var.admin_pass
  #   resource_group_name   = azurerm_resource_group.RG.name
  #   network_interface_ids = [azurerm_network_interface.web_3.id]
  #   size                  = "Standard_B1ms"
  #   availability_set_id   = azurerm_availability_set.ASet.id

  #   disable_password_authentication   = true  #Force Authentication by SSH Key

  #   source_image_reference  {
  #     publisher = "Canonical"
  #     offer     = "UbuntuServer"
  #     sku       = "18.04-LTS"
  #     version   = "latest"
  #   }

  #   os_disk {
  #     name                  = "${var.prefix}-OSdisk-web-3"
  #     storage_account_type  = "Premium_LRS"
  #     caching               = "ReadWrite"
  #   }

  #   admin_ssh_key {
  #     username   = var.admin_user
  #     public_key = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-3/id_rsa.pub")
  #   }
  # }

#================================================
# ELK STACK PROJECT RESOURCES
#================================================
# # Define Network Resources
#   resource "azurerm_virtual_network" "ELKNet" {
#     name                = "${var.prefix}_ELKNet"
#     resource_group_name = azurerm_resource_group.RG.name
#     location            = var.region_2
#     address_space       = ["10.0.0.0/16",]
#   }

#   resource "azurerm_virtual_network_peering" "C_peer" {
#   name                      = "central-to-westcentral"
#   resource_group_name       = azurerm_resource_group.RG.name
#   virtual_network_name      = azurerm_virtual_network.VNet.name
#   remote_virtual_network_id = azurerm_virtual_network.ELKNet.id
# }

# resource "azurerm_virtual_network_peering" "WC_peer" {
#   name                      = "westcentral-to-central"
#   resource_group_name       = azurerm_resource_group.RG.name
#   virtual_network_name      = azurerm_virtual_network.ELKNet.name
#   remote_virtual_network_id = azurerm_virtual_network.VNet.id
# }

# ### Define web-4 ###    NOTE: Cant be deployed, will exceed regional cores quota on free tier

#   resource "azurerm_network_interface" "web_4" {
#     name                = "${var.prefix}-web-4-nic"
#     location            = var.region_2
#     resource_group_name = azurerm_resource_group.RG.name

#     ip_configuration {
#       name                          = "web_4"
#       subnet_id                     = azurerm_subnet.internal.id
#       private_ip_address_allocation = "Dynamic"
#     }
#   }

#   resource "azurerm_key_vault_key" "web_4" {
#     name         = "web-4-public-key"
#     key_vault_id = azurerm_key_vault.KV.id
#     key_type     = "RSA"
#     key_size     = 2048

#     key_opts = [
#       "decrypt",
#       "encrypt",
#       "sign",
#       "unwrapKey",
#       "verify",
#       "wrapKey",
#     ]
#   }

#   resource "azurerm_key_vault_secret" "web_4" {
#     name         = "web-4-private-key"
#     key_vault_id = azurerm_key_vault.KV.id
#     value        = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-4/id_rsa")
#   }

#   resource "azurerm_linux_virtual_machine" "web_4" {
#     depends_on = [
#       azurerm_key_vault_secret.web_4,
#       azurerm_key_vault_key.web_4,
#     ]
#     name                  = "${var.prefix}-web-4"
#     location              = var.region_2
#     computer_name         = "web-4"
#     admin_username        = var.admin_user
#     admin_password        = var.admin_pass
#     resource_group_name   = azurerm_resource_group.RG.name
#     network_interface_ids = [azurerm_network_interface.web_4.id]
#     size                  = "Standard_B1ms"
#     # availability_set_id   = azurerm_availability_set.ASet.id

#     disable_password_authentication   = true  #Force Authentication by SSH Key

#     source_image_reference  {
#       publisher = "Canonical"
#       offer     = "UbuntuServer"
#       sku       = "18.04-LTS"
#       version   = "latest"
#     }

#     os_disk {
#       name                  = "${var.prefix}-OSdisk-web-4"
#       storage_account_type  = "Premium_LRS"
#       caching               = "ReadWrite"
#     }

#     admin_ssh_key {
#       username   = var.admin_user
#       public_key = file("C:/Users/smith/repos/hashicorp/terraform/azure/${var.region}/.ssh/web-4/id_rsa.pub")
#     }
#   }