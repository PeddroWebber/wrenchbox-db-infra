output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "tfstate_storage_account" {
  value = azurerm_storage_account.tfstate.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "databases" {
  value = {
    homolog = azurerm_postgresql_flexible_server_database.homolog.name
    prod    = azurerm_postgresql_flexible_server_database.prod.name
  }
}
