terraform {
  required_version = ">=1.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.5"
    }
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "rg-trabalho-terraform" {
  name     = "rg-trabalho-terraform"
  location = "East US"

  tags = {
    faculdade = "Impacta"
  }
}



resource "azurerm_virtual_network" "vnet-trabalho" {
  name                = "vnet-trabalho"
  location            = azurerm_resource_group.rg-trabalho-terraform.location
  resource_group_name = azurerm_resource_group.rg-trabalho-terraform.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    faculdade   = "impacta"
    environment = "Production"
  }
}

resource "azurerm_subnet" "sub-trabalho" {
  name                 = "sub-trabalho"
  resource_group_name  = azurerm_resource_group.rg-trabalho-terraform.name
  virtual_network_name = azurerm_virtual_network.vnet-trabalho.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_public_ip" "pip-trabalho" {
  name                = "pip-trabalho"
  location            = azurerm_resource_group.rg-trabalho-terraform.location
  resource_group_name = azurerm_resource_group.rg-trabalho-terraform.name
  allocation_method   = "Static"

  tags = {
    faculdade = "Impacta"
  }
}

resource "azurerm_network_security_group" "vsectrabalho" {
  name                = "vsectrabalho"
  location            = azurerm_resource_group.rg-trabalho-terraform.location
  resource_group_name = azurerm_resource_group.rg-trabalho-terraform.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  
  security_rule {
    name                       = "Web"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    faculdade   = "Impacta"
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic-trabalho" {
  name                = "nic-trabalho"
  location            = azurerm_resource_group.rg-trabalho-terraform.location
  resource_group_name = azurerm_resource_group.rg-trabalho-terraform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub-trabalho.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-trabalho.id
  }
  tags = {
    faculdade = "Impacta"
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-trabalho" {
  network_interface_id      = azurerm_network_interface.nic-trabalho.id
  network_security_group_id = azurerm_network_security_group.vsectrabalho.id
}

resource "azurerm_linux_virtual_machine" "vm-trabalho-terraform" {
  name                = "vm-trabalho-terraform"
  location            = azurerm_resource_group.rg-trabalho-terraform.location
  resource_group_name = azurerm_resource_group.rg-trabalho-terraform.name
  size                = "Standard_DS1_v2"

  admin_username                  = "adminuser"
  admin_password                  = "T3rr@F0rm!2#"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic-trabalho.id
  ]

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

  connection {
    type        = "ssh"
    host        = azurerm_linux_virtual_machine.vm-trabalho-terraform.public_ip_address
    user        = azurerm_linux_virtual_machine.vm-trabalho-terraform.admin_username
    password    = azurerm_linux_virtual_machine.vm-trabalho-terraform.admin_password
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }
provisioner "local-exec" {
    command = "echo ${azurerm_linux_virtual_machine.vm-trabalho-terraform.public_ip_address} > ip_address.txt"
  }
}