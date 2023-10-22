terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.75.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "univigo-rg"
    storage_account_name = "terraform"
    container_name       = "tfstate"
    key                  = "k8s.tfstate"
  }
}


provider "azurerm" {
  features {}
}

