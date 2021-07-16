terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.66.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

/* Resource Group to lay the resources for VM creation*/
resource "azurerm_resource_group" "azureresourcegroupterra" {
    name = "myresourceGrpVMTest"
    location = "eastus"
    tags = {
        environment = "Terraform Demo"
    }
}

/* Create a virtual network inside the Resource Group, VM lies inside the Virtual network */

resource "azurerm_virtual_network" "azurevirtualnetworkterra" {
    name = "myVnet"
    location = "eastus"
    resource_group_name = azurerm_resource_group.azureresourcegroupterra.name
    tags = {
        environment = "Terraform Demo"
    }
    address_space = ["10.1.0.0/16"]
}

/* Create a subnet inside Virtual Network */
resource "azurerm_subnet" "azuresubnetterra" {
    name = "myFirstSubnet"
    resource_group_name = azurerm_resource_group.azureresourcegroupterra.name
    virtual_network_name = azurerm_virtual_network.azurevirtualnetworkterra.name
    address_prefixes = ["10.1.0.0/24"]
}

/* Assign public ip for the VM to be accesible to the internet */
resource "azurerm_public_ip" "azurepublicipterra" {
    name = "myPublicIp"
    location = "eastus"
    resource_group_name = azurerm_resource_group.azureresourcegroupterra.name
    tags = {
        environment = "Terraform Demo"
    }
    allocation_method = "Dynamic"
}

/* Network security group to control traffic in and out of VM */
resource "azurerm_network_security_group" "azurenetworksecuritygroupterra" {
    name = "myNSG"
    location = "eastus"
    resource_group_name = azurerm_resource_group.azureresourcegroupterra.name
    tags = {
        environment = "Terraform Demo"
    }

    security_rule {
        name = "SSH"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"

    }  
}

/* Virtual network interface connects VM to the VN,public IP,NSG */
resource "azurerm_network_interface" "azurenetworkinterfaceterra" {
    name = "myNetworkInterface"
    location = "eastus"
    resource_group_name = azurerm_resource_group.azureresourcegroupterra.name
    tags = {
        environment = "Terraform Demo"
    }

    ip_configuration {
        name = "myNetworkInterfaceConfiguration"
        subnet_id = azurerm_subnet.azuresubnetterra.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.azurepublicipterra.id
    }
}

/* Connect network interface with network security group */
resource "azurerm_network_interface_security_group_association" "azurenetworkinterfacesecuritygroupassociationterra" {
    network_interface_id = azurerm_network_interface.azurenetworkinterfaceterra.id
    network_security_group_id = azurerm_network_security_group.azurenetworksecuritygroupterra.id
}

/* Storage account to store boot diagnostics which will be usefull in trouble shooting */

resource "random_id" "azurerandomidterra" {
    keepers = {
        resource_group = azurerm_resource_group.azureresourcegroupterra.name
    }
    byte_length = 8
}

resource "azurerm_storage_account" "azurestorageaccountterra" {
    name = "diag${random_id.azurerandomidterra.hex}"
    resource_group_name = azurerm_resource_group.azureresourcegroupterra.name
    location = "eastus"
    tags = {
        environment = "Terraform Demo"
    }
    account_replication_type = "LRS"
    account_tier = "Standard"
}

/* Create VM and use all the resources created above */

resource "tls_private_key" "azurevmprivatekey" {
    algorithm = "RSA"
    rsa_bits = 4096
}

output "tls_private_key" {
    value = tls_private_key.azurevmprivatekey.private_key_pem
    sensitive = true
}

/* VM configuration Starts */

resource "azurerm_linux_virtual_machine" "azurevirtualmachineterra" {
    name = "myVirtalMachine"
    location = "eastus"
    resource_group_name = azurerm_resource_group.azureresourcegroupterra.name
    tags = {
        environment = "Terraform Demo"
    }
    network_interface_ids = [azurerm_network_interface.azurenetworkinterfaceterra.id,]
    size = "Standard_DS1_v2"

    os_disk {
        name = "myOsDisk"
        caching = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "latest"
    }

    computer_name = "myazurevm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.azurestorageaccountterra.primary_blob_endpoint
    }
}


