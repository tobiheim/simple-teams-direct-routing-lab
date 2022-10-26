## Learning Phone Lab Variables
variable "subscription_id" {
    type = string
    description = "Azure Subscription Id"
}
variable "tenant_id" {
    type = string
    description = "Azure Tenant Id"
}
variable "location" {
    default = "westus"
    type = string
    description = "Azure Region to deploy resources"
}
variable "resource_group_name" {
    default = "learning-phone-rg"
    type = string
    description = "Azure Resource Group Name"
}
variable "sbc_vm_name" {
    default = "sbc01"
    type = string
    description = "Value for the SBC VM Name"
}
variable "sbc_vm_size" {
    default = "Standard_DS1_v2"
    type = string
    description = "Value for the SBC VM Size"
}
variable "admin_host_name" {
    default = "admin-host"
    type = string
    description = "Value for the Admin Host VM Host Name"
}
variable "admin_host_vm_size" {
    default = "Standard_DS1_v2"
    type = string
    description = "Value for the Admin Host VM Size"
}

## Learning Phone Lab Resources

# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.25.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  features {}
}

# Create Random String for Storage Account Name
resource "random_string" "storage_account_name" {
  length = 16
  special = false
  lower = true
  upper = false
  numeric = false
}
# Create Random String for 10 character sufffix
resource "random_string" "name_3_suffix" {
  length = 10
  special = false
  lower = true
  upper = false
  numeric = false
}
# Create Random String for 3 character suffix
resource "random_string" "name_10_suffix" {
  length = 3
  special = false
  lower = true
  upper = false
  numeric = false
}
resource "random_string" "sbc_default_pwd" {
  length = 10
  special = true
  min_lower = 1
  min_upper = 1
  min_special = 1
  override_special = "!@#$"
}
resource "random_string" "admin_host_default_pwd" {
  length = 10
  special = true
  min_lower = 1
  min_upper = 1
  min_special = 1
  override_special = "!@#$"
}

# Local Variables
locals {
  storage_account_name = "${random_string.storage_account_name.result}"
}

# Create Azure resource group
resource "azurerm_resource_group" "res-1" {
  location = var.location
  name     = var.resource_group_name
}
# Create SBC VM
resource "azurerm_linux_virtual_machine" "res-0" {
  admin_password                  = "${random_string.sbc_default_pwd.result}"
  admin_username                  = "labadmin"
  disable_password_authentication = false
  location                        = var.location
  name                            = var.sbc_vm_name
  network_interface_ids           = [azurerm_network_interface.res-6.id]
  resource_group_name             = var.resource_group_name
  size                            = var.sbc_vm_size
  boot_diagnostics {
    storage_account_uri = "https://${local.storage_account_name}.blob.core.windows.net/"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  plan {
    name      = "mediantvesbcazure"
    product   = "mediantsessionbordercontroller"
    publisher = "audiocodes"
  }
  source_image_reference {
    offer     = "mediantsessionbordercontroller"
    publisher = "audiocodes"
    sku       = "mediantvesbcazure"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-6,
    azurerm_storage_account.res-22
  ]
}
# Create Network Interface for SBC VM
resource "azurerm_network_interface" "res-6" {
  location            = var.location
  name                = "sbc-eth0"
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.res-19.id
    subnet_id                     = azurerm_subnet.res-21.id
  }
  depends_on = [
    azurerm_public_ip.res-19,
    azurerm_subnet.res-21,
  ]
}
# Create Network Security Group for SBC VM
resource "azurerm_network_interface_security_group_association" "res-7" {
  network_interface_id      = azurerm_network_interface.res-6.id
  network_security_group_id = azurerm_network_security_group.res-11.id
  depends_on = [
    azurerm_network_interface.res-6,
    azurerm_network_security_group.res-11,
  ]
}
# Create SBC Network Security Group
resource "azurerm_network_security_group" "res-11" {
  location            = var.location
  name                = "sbc-nsg"
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_resource_group.res-1,
  ]
}
# Create SBC Network Security Group Rule for Web Interface
resource "azurerm_network_security_rule" "res-12" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "80"
  direction                   = "Inbound"
  name                        = "http"
  network_security_group_name = "sbc-nsg"
  priority                    = 510
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-11,
  ]
}
# Create SBC Network Security Group Rule for HTTPS
resource "azurerm_network_security_rule" "res-13" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "443"
  direction                   = "Inbound"
  name                        = "https"
  network_security_group_name = "sbc-nsg"
  priority                    = 520
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-11,
  ]
}
# Create SBC Network Security Group Rule for Media Ports
resource "azurerm_network_security_rule" "res-14" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "6000 - 6399"
  direction                   = "Inbound"
  name                        = "media"
  network_security_group_name = "sbc-nsg"
  priority                    = 1020
  protocol                    = "Udp"
  resource_group_name         = var.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-11,
  ]
}
# Create SBC Network Security Group Rule for Signaling Ports TCP
resource "azurerm_network_security_rule" "res-15" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "5061"
  direction                   = "Inbound"
  name                        = "sip-tcp"
  network_security_group_name = "sbc-nsg"
  priority                    = 1010
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-11,
  ]
}
# Create SBC Network Security Group Rule for Signaling Ports UDP
resource "azurerm_network_security_rule" "res-16" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "5060"
  direction                   = "Inbound"
  name                        = "sip-udp"
  network_security_group_name = "sbc-nsg"
  priority                    = 1000
  protocol                    = "Udp"
  resource_group_name         = var.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-11,
  ]
}
# Create SBC Public IP
resource "azurerm_public_ip" "res-19" {
  allocation_method   = "Static"
  domain_name_label   = "sbc-${random_string.name_10_suffix.result}"
  location            = var.location
  name                = "sbc-ip"
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_resource_group.res-1,
  ]
}
# Create SBC Subnet
resource "azurerm_virtual_network" "res-20" {
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  name                = "sbc-vnet"
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_resource_group.res-1,
  ]
}
# Create SBC Subnet 2
resource "azurerm_subnet" "res-21" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "subnet-1"
  resource_group_name  = var.resource_group_name
  virtual_network_name = "sbc-vnet"
  depends_on = [
    azurerm_virtual_network.res-20,
  ]
}
# Create Admin Host VM
resource "azurerm_windows_virtual_machine" "res-2" {
  admin_password        = "${random_string.admin_host_default_pwd.result}"
  admin_username        = "labadmin"
  license_type          = "Windows_Client"
  location              = var.location
  name                  = var.admin_host_name
  network_interface_ids = [azurerm_network_interface.res-4.id]
  resource_group_name   = var.resource_group_name
  size                  = var.admin_host_vm_size
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    offer     = "windows-11"
    publisher = "microsoftwindowsdesktop"
    sku       = "win11-22h2-ent"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-4,
  ]
}
# Create auto-shutdown schedule for Admin Host VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "res-3" {
  daily_recurrence_time = "1900"
  location              = var.location
  timezone              = "UTC"
  virtual_machine_id    = azurerm_windows_virtual_machine.res-2.id
  notification_settings {
    enabled = false
  }
  depends_on = [
    azurerm_windows_virtual_machine.res-2,
  ]
}
# Create auto-shutdown schedule for SBC VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "res-25" {
  daily_recurrence_time = "1900"
  location              = var.location
  timezone              = "UTC"
  virtual_machine_id    = azurerm_linux_virtual_machine.res-0.id
  notification_settings {
    enabled = false
  }
  depends_on = [
    azurerm_linux_virtual_machine.res-0
  ]
}
#Create Network Interface for Admin Host VM
resource "azurerm_network_interface" "res-4" {
  location            = var.location
  name                = "admin-host${random_string.name_3_suffix.result}"
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.res-18.id
    subnet_id                     = azurerm_subnet.res-21.id
  }
  depends_on = [
    azurerm_public_ip.res-18,
    azurerm_subnet.res-21,
  ]
}
# Create Network Security Group for Admin Host VM
resource "azurerm_network_interface_security_group_association" "res-5" {
  network_interface_id      = azurerm_network_interface.res-4.id
  network_security_group_id = azurerm_network_security_group.res-8.id
  depends_on = [
    azurerm_network_interface.res-4,
    azurerm_network_security_group.res-8,
  ]
}
# Create Admin Host Network Securtiy Group
resource "azurerm_network_security_group" "res-8" {
  location            = var.location
  name                = "admin-host-nsg"
  resource_group_name = var.resource_group_name
  depends_on = [
    azurerm_resource_group.res-1,
  ]
}
# Create Admin Host Network Security Group Rule for Syslog
resource "azurerm_network_security_rule" "res-9" {
  access                      = "Allow"
  description                 = "Syslog"
  destination_address_prefix  = "*"
  destination_port_range      = "514"
  direction                   = "Inbound"
  name                        = "AllowAnyCustom514Inbound"
  network_security_group_name = "admin-host-nsg"
  priority                    = 310
  protocol                    = "Udp"
  resource_group_name         = var.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-8,
  ]
}
# Create Admin Host Network Security Group Rule for RDP
resource "azurerm_network_security_rule" "res-10" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  direction                   = "Inbound"
  name                        = "RDP"
  network_security_group_name = "admin-host-nsg"
  priority                    = 300
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-8,
  ]
}
# Create Admin Host Public IP
resource "azurerm_public_ip" "res-18" {
  allocation_method   = "Static"
  location            = var.location
  name                = "admin-host-ip"
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.res-1,
  ]
}
# Create Azure Storage Account
resource "azurerm_storage_account" "res-22" {
  account_kind              = "Storage"
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = false
  location                  = var.location
  min_tls_version           = "TLS1_0"
  name                      = local.storage_account_name
  resource_group_name       = var.resource_group_name
  depends_on = [
    azurerm_resource_group.res-1,
  ]
}
# Create Azure Storage Container
resource "azurerm_storage_container" "res-24" {
  name                 = "bootdiagnostics-sbc-164d9047-a954-4be0-bba4-85${random_string.name_10_suffix.result}"
  storage_account_name = local.storage_account_name
  depends_on = [
    azurerm_storage_account.res-22,
  ]
}
# Output after deployment
output "SBC_Public_IP_Address" {
  description = "Public IP of SBC"
  value       = azurerm_public_ip.res-19.ip_address
}
output "SBC_Private_IP_Address" {
  description = "Private IP of SBC"
  value       = azurerm_linux_virtual_machine.res-0.private_ip_address
}
output "Admin_Host_Public_IP_Address" {
  description = "Public IP of Admin Host"
  value       = azurerm_public_ip.res-18.ip_address
}
output "Admin_Host_Private_IP_Address" {
  description = "Private IP of Admin Host"
  value       = azurerm_windows_virtual_machine.res-2.private_ip_address
}
output "Admin_Host_Password" {
  description = "Password of Admin Host"
  sensitive = true
  value       = azurerm_windows_virtual_machine.res-2.admin_password
}
output "SBC_Password" {
  description = "Password of SBC"
  sensitive = true
  value       = azurerm_linux_virtual_machine.res-0.admin_password
}