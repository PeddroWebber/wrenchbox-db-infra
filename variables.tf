variable "location" {
  type    = string
  default = "brazilsouth"
}

variable "resource_group_name" {
  type    = string
  default = "rg-wrenchbox"
}

variable "operator_ip" {
  type        = string
  default     = ""
  description = "IPv4 do operador ou do runner, liberado no firewall só durante a criação dos papéis."
}
