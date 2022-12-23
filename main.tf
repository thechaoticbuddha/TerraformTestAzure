########## start provider
terraform {
  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
}
provider "azurerm" {
  features {
      key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

##########################end provider

####################### client config data #######

data "azurerm_client_config" "current" {}



########################### client config data#####


#########remotebackend####

terraform {
  backend "azurerm" {
    resource_group_name  = "tfdemostaterg"
    storage_account_name = "tfdemostatesa"
    container_name       = "tfstate"
    key                  = "gx9GShnv+rtUkJ0YnoT/GhlKMpntaDc0PnQwF0TWg7qqmhgUWX+sfI6roBSTKdMI2aNmK8y8zT8o+AStdqIi8w=="
  }
}



# Create our Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "tfdemo-app01"
  location = "eastus"
}


###########################
# Create our Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "tfdemovnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "terraform"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = ["10.0.1.0/24"]
}
# Create our Azure Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "tfdemosa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "POC"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "tfdemonic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine
resource "azurerm_virtual_machine" "tfdemovm01" {
  name                  = "jonnychipzvm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "tfdemovm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name      = "grvtfdemo"
    admin_username     = "grvadmin"
    admin_password     = "Password123$"
  }
  os_profile_windows_config {
  }
}