data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "random_password" "app" {
  length  = 32
  special = false
}

resource "random_password" "auth" {
  length  = 32
  special = false
}

resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "random_password" "notify" {
  length  = 32
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "sttfwb${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_key_vault" "main" {
  name                       = "kvwb${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

resource "azurerm_role_assignment" "terraform_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "psql-wrenchbox-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "16"
  administrator_login           = "wrenchboxadmin"
  administrator_password        = random_password.admin.result
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  backup_retention_days         = 7
  zone                          = "1"
  public_network_access_enabled = true

  authentication {
    password_auth_enabled = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "homolog" {
  name      = "wrenchbox_homolog"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "prod" {
  name      = "wrenchbox_prod"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "operator" {
  count            = var.operator_ip == "" ? 0 : 1
  name             = "operator"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = var.operator_ip
  end_ip_address   = var.operator_ip
}

locals {
  databases = {
    homolog = azurerm_postgresql_flexible_server_database.homolog.name
    prod    = azurerm_postgresql_flexible_server_database.prod.name
  }
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "postgres-admin-password"
  value        = random_password.admin.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.terraform_secrets]
}

resource "azurerm_key_vault_secret" "jwt" {
  name         = "jwt-secret"
  value        = random_password.jwt.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.terraform_secrets]
}

resource "azurerm_key_vault_secret" "notify" {
  name         = "notify-key"
  value        = random_password.notify.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.terraform_secrets]
}

resource "azurerm_key_vault_secret" "app_connection" {
  for_each     = local.databases
  name         = "customers-app-connection-${each.key}"
  value        = "Host=${azurerm_postgresql_flexible_server.main.fqdn};Port=5432;Database=${each.value};Username=wrenchbox_app;Password=${random_password.app.result};SSL Mode=Require;Trust Server Certificate=true"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.terraform_secrets]
}

resource "azurerm_key_vault_secret" "auth_connection" {
  for_each     = local.databases
  name         = "customers-auth-connection-${each.key}"
  value        = "Host=${azurerm_postgresql_flexible_server.main.fqdn};Port=5432;Database=${each.value};Username=wrenchbox_auth;Password=${random_password.auth.result};SSL Mode=Require;Trust Server Certificate=true"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.terraform_secrets]
}
