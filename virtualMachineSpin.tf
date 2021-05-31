resource "azurerm_virtual_network" "secondTestResource" {
  name                = "secondTestResource-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.secondTestResource.location
  resource_group_name = azurerm_resource_group.secondTestResource.name
}

resource "azurerm_subnet" "secondTestResource" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.secondTestResource.name
  virtual_network_name = azurerm_virtual_network.secondTestResource.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "secondTestResource" {
  name                = "secondTestResource-nic"
  location            = azurerm_resource_group.secondTestResource.location
  resource_group_name = azurerm_resource_group.secondTestResource.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.secondTestResource.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "secondTestResource" {
	name = "VMInstanceTerraform"
	resource_group_name = azurerm_resource_group.secondTestResource.name
	location = azurerm_resource_group.secondTestResource.location
	size = "Standard_B1ls"
	network_interface_ids = [
    	azurerm_network_interface.secondTestResource.id,
  	]

	admin_username = "******"
	admin_password = "******"
	disable_password_authentication = false
  	
  	os_disk {
    	caching              = "ReadWrite"
    	storage_account_type = "Standard_LRS"
  	}

  	source_image_reference {
    	publisher = "Canonical"
    	offer     = "UbuntuServer"
    	sku       = "16.04-LTS"
    	version   = "latest"
  	}
}
