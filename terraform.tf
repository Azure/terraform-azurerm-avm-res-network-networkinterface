terraform {
  required_version = "~> 1.9.6"
  required_providers {
    # TODO: Ensure all required providers are listed here and the version property includes a constraint on the maximum major version.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    modtm = {
      source  = "Azure/modtm"
      version = "0.3.2"
    }
  }
}
