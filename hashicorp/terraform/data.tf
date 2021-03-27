#==========================================================
# Data Space - runs at compile time to see current values
#==========================================================

# Get the external ip address of this machine
data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {} # Has something to do with 'resource "azurerm_key_vault" "KeyVault"'

# Private Keys
    # data "azurerm_key_vault_secret" "jumpbox-priv" {
    #     depends_on = [
    #         azurerm_key_vault.KV
    #     ]
    #     name         = "jumpbox-private-key"
    #     key_vault_id = data.azurerm_key_vault.KV.id
    # } 

    # data "azurerm_key_vault_secret" "web_priv" {
    #     depends_on = [
    #         azurerm_key_vault.KV
    #     ]
    #     name         = "web-private-key"
    #     key_vault_id = data.azurerm_key_vault.KV.id
    # } 

# Public Keys
    # data "azurerm_key_vault_key" "jumpbox_pub" {
    #     name         = "jumpbox-public-key"
    #     key_vault_id = azurerm_key_vault.KV.id
    # }

    # data "azurerm_key_vault_key" "web_pub" {
    #     name         = "web-public-key"
    #     key_vault_id = data.azurerm_key_vault.web_pub.id
    # }

# SSH Keys
    # data "azurerm_ssh_public_key" "jumpbox-pub" {
    #     name                = "jumpbox-public-key"
    #     resource_group_name = "azurerm_resource_group.RG.name"
    # }