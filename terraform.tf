terraform {
  # check blocks and plantimestamp() need Terraform 1.5 or later.
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}
