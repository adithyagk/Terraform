terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.61.0"
    }
  }
}
resource "azurerm_resource_group" "firstresource" {
  name     = "firstresource"
  location = "West Europe"
}

resource "azurerm_resource_group" "secondTestResource" {
  name	   = "secondresource"
  location = "Central India"
}
provider "azurerm"  {
features{}
}
