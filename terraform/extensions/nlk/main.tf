terraform {
  required_version = "~> 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.97"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_kubernetes_cluster_extension" "nlk" {
  name           = "test-ext"
  # fill out cluster ID.
  cluster_id     = "/subscriptions/ee920d60-90f3-4a92-b5e7-bb284c3a6ce2/resourceGroups/testenv-900d48c0-aks-resources/providers/Microsoft.ContainerService/managedClusters/testenv-900d48c0-aks"
  extension_type = "nginxinc.nginxaas-aks-extension"
  release_namespace = "nlk"
  # release_train will be "Stable" after publishing the offer.
  release_train = "Preview"
  plan {
    name = "f5-nginx-for-azure-aks-extension"
    product = "f5-nginx-for-azure-aks-extension"
    publisher = "f5-networks"
  }

  configuration_settings = {
    "nlk.dataplaneApiKey" = "testmyKey123456!"
    "nlk.config.nginxHosts" = "https://nlkdemo-d81e16277aa1.westcentralus.nginxaas.net/nplus"
  }
}
