output "ip_address" {
  description = "IP address of NGINXaaS deployment."
  value       = azurerm_nginx_deployment.example.ip_address
}

output "waf_status" {
  description = "waf status of NGINXaaS deployment."
  value       = azurerm_nginx_deployment.example.web_application_firewall[0].status
}