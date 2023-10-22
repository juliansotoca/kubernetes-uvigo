data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vm_network" {
  name                = var.virtual_network
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "network_subnet" {
  name                 = var.subnet
  virtual_network_name = var.virtual_network
  resource_group_name  = var.resource_group_name
}

// Import SSH keys
data "azurerm_ssh_public_key" "juliansotoca_key" {
  name                = "juliansotoca"
  resource_group_name = data.azurerm_resource_group.rg.name
}
