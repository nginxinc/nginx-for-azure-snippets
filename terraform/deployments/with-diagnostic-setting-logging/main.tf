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

module "prerequisites" {
  source   = "../../prerequisites"
  location = var.location
  name     = var.name
  tags     = var.tags
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = module.prerequisites.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = var.tags
}

resource "azurerm_nginx_deployment" "example" {
  name                     = var.name
  resource_group_name      = module.prerequisites.resource_group_name
  sku                      = var.sku
  location                 = var.location
  capacity                 = 20
  diagnose_support_enabled = false # This enables metrics to azure monitoring, not nginx logs

  # Required for diagnostic setting logging
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [module.prerequisites.managed_identity_id]
  }

  frontend_public {
    ip_address = [module.prerequisites.public_ipv4_address_id]
  }
  network_interface {
    subnet_id = module.prerequisites.subnet_id
  }

  tags = var.tags
}

resource "azurerm_nginx_configuration" "example" {
  nginx_deployment_id = azurerm_nginx_deployment.example.id
  root_file           = "/etc/nginx/nginx.conf"

  config_file {
    content = base64encode(<<-EOT
user nginx;
worker_processes auto;
worker_rlimit_nofile 8192;
pid /run/nginx/nginx.pid;

events {
    worker_connections 4000;
}

http {
    log_format access_format '$remote_addr - "$remote_user" [$time_local] "$request" $status';
    error_log /var/log/nginx/error.log error;
    access_log /var/log/nginx/access.log access_format;
    server {
        listen 80 default_server;
        server_name localhost;
        location = / {
            return 200 'Hello World';
        }
    }
}
EOT
    )
    virtual_path = "/etc/nginx/nginx.conf"
  }
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name               = "${azurerm_nginx_deployment.example.name}-logs"
  target_resource_id = azurerm_nginx_deployment.example.id
  storage_account_id = azurerm_storage_account.example.id

  enabled_log {
    category = "NginxLogs"
  }
}
