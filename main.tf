terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "nadi_tf" {
  name     = var.rg_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet_tf" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.nadi_tf.name
  location            = azurerm_resource_group.nadi_tf.location
  address_space       = ["10.0.0.0/16"]

  tags = local.tags
}

resource "azurerm_subnet" "subnet_tf" {
  name                 = "subnet_tf"
  resource_group_name  = azurerm_resource_group.nadi_tf.name
  virtual_network_name = azurerm_virtual_network.vnet_tf.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg_tf" {
  name                = var.nsg_name
  location            = azurerm_resource_group.nadi_tf.location
  resource_group_name = azurerm_resource_group.nadi_tf.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "nsg_rule_allowall_tf" {
  name                        = var.nsg_rule_name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.nadi_tf.name
  network_security_group_name = azurerm_network_security_group.nsg_tf.name

}

resource "azurerm_subnet_network_security_group_association" "nadi_nsga_tf" {
  subnet_id                 = azurerm_subnet.subnet_tf.id
  network_security_group_id = azurerm_network_security_group.nsg_tf.id
}

resource "azurerm_public_ip" "publicip_tf" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.nadi_tf.name
  location            = azurerm_resource_group.nadi_tf.location
  allocation_method   = "Dynamic"

  tags = local.tags
}

resource "azurerm_network_interface" "nic_tf" {
  name                = var.nic_name
  location            = azurerm_resource_group.nadi_tf.location
  resource_group_name = azurerm_resource_group.nadi_tf.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_tf.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip_tf.id
  }

  tags = local.tags
}

resource "azurerm_linux_virtual_machine" "example" {
  name                  = var.vm_name
  resource_group_name   = azurerm_resource_group.nadi_tf.name
  location              = azurerm_resource_group.nadi_tf.location
  size                  = "Standard_B1s"
  admin_username        = "nadi"
  network_interface_ids = [azurerm_network_interface.nic_tf.id]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "nadi"
    public_key = file("~/.ssh/linuxvm_tf.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname     = self.public_ip_address
      user         = "nadi"
      identityfile = "~/.ssh/linuxvm_tf"
    })
    interpreter = var.host_os == "windows" ? ["PowerShell", "-Command"] : ["bash", "-c"]

  }

  tags = local.tags

}

data "azurerm_public_ip" "tf-ip-data" {
  name                = azurerm_public_ip.publicip_tf.name
  resource_group_name = azurerm_resource_group.nadi_tf.name

}

output "public-ip-addr" {
  value = "${azurerm_linux_virtual_machine.example.name}: ${data.azurerm_public_ip.tf-ip-data.ip_address}"
}