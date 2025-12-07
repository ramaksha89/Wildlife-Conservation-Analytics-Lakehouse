# Wildlife Conservation Analytics Lakehouse - Terraform Configuration
# Main infrastructure orchestration file

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
  
  backend "azurerm" {
    # Backend configuration for state management
    resource_group_name  = "wildlife-terraform-state-rg"
    storage_account_name = "wildlifestatesa"
    container_name       = "tfstate"
    key                  = "wildlife-lakehouse.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "wildlife_rg" {
  name     = var.resource_group_name
  location = var.location
  
  tags = merge(
    var.common_tags,
    {
      Project     = "Wildlife Conservation Analytics"
      Environment = var.environment
    }
  )
}

# Azure Data Lake Storage Gen2
module "storage" {
  source = "./modules/storage"
  
  resource_group_name = azurerm_resource_group.wildlife_rg.name
  location            = azurerm_resource_group.wildlife_rg.location
  storage_account_name = var.storage_account_name
  tags                = var.common_tags
}

# Azure Databricks Workspace
module "databricks" {
  source = "./modules/databricks"
  
  resource_group_name   = azurerm_resource_group.wildlife_rg.name
  location              = azurerm_resource_group.wildlife_rg.location
  databricks_workspace_name = var.databricks_workspace_name
  sku                   = var.databricks_sku
  tags                  = var.common_tags
}

# Azure Data Factory
module "adf" {
  source = "./modules/adf"
  
  resource_group_name = azurerm_resource_group.wildlife_rg.name
  location            = azurerm_resource_group.wildlife_rg.location
  adf_name            = var.adf_name
  tags                = var.common_tags
}

# Azure Key Vault
module "keyvault" {
  source = "./modules/keyvault"
  
  resource_group_name = azurerm_resource_group.wildlife_rg.name
  location            = azurerm_resource_group.wildlife_rg.location
  keyvault_name       = var.keyvault_name
  tenant_id           = var.tenant_id
  tags                = var.common_tags
}

# Outputs
output "databricks_workspace_url" {
  value       = module.databricks.workspace_url
  description = "The URL of the Databricks workspace"
}

output "storage_account_id" {
  value       = module.storage.storage_account_id
  description = "The ID of the storage account"
}

output "adf_id" {
  value       = module.adf.adf_id
  description = "The ID of Azure Data Factory"
}
