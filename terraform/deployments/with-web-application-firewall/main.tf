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
  subscription_id = "ee920d60-90f3-4a92-b5e7-bb284c3a6ce2"
}

module "prerequisites" {
  source   = "../../prerequisites"
  location = var.location
  name     = var.name
  tags     = var.tags
}

resource "azurerm_nginx_deployment" "example" {
  name                      = var.name
  resource_group_name       = module.prerequisites.resource_group_name
  sku                       = var.sku
  location                  = var.location
  capacity                  = 20
  automatic_upgrade_channel = "stable"
  diagnose_support_enabled  = true
  identity {
    type         = "UserAssigned"
    identity_ids = [module.prerequisites.managed_identity_id]
  }
  frontend_public {
    ip_address = [module.prerequisites.public_ip_address_id]
  }
  network_interface {
    subnet_id = module.prerequisites.subnet_id
  }
  nginx_app_protect {
    web_application_firewall_settings {
      activation_state = "Enabled"
    }
  }
  tags = var.tags
}

resource "azurerm_nginx_configuration" "example-config" {
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

error_log /var/log/nginx/error.log error;

http {
    server {
        listen 80 default_server;
        server_name localhost;
        location / {
            return 200 'Hello World';
        }
    }
}
EOT
    )
    virtual_path = "/etc/nginx/nginx.conf"
  }
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_nginx_deployment.example.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = module.prerequisites.managed_identity_principal_id
}
