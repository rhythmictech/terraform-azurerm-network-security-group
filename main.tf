resource "azurerm_resource_group" "nsg" {
  count    = var.resource_group_create ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.security_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

#############################
#   Simple security rules   #
#############################

resource "azurerm_network_security_rule" "predefined_rules" {
  count                       = length(var.predefined_rules)
  name                        = lookup(var.predefined_rules[count.index], "name")
  priority                    = lookup(var.predefined_rules[count.index], "priority", 4096 - length(var.predefined_rules) + count.index)
  direction                   = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 0)
  access                      = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 1)
  protocol                    = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 2)
  source_port_ranges          = length(split(",", lookup(var.predefined_rules[count.index], "source_port_range", "*"))) > 1 ? split(",", replace(lookup(var.predefined_rules[count.index], "source_port_range", "0-65535"), "*", "0-65535")) : null
  source_port_range           = length(split(",", lookup(var.predefined_rules[count.index], "source_port_range", "*"))) == 1 ? lookup(var.predefined_rules[count.index], "source_port_range", "*") : null
  destination_port_range      = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 4)
  description                 = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 5)
  source_address_prefix       = join(",", var.source_address_prefix)
  destination_address_prefix  = join(",", var.destination_address_prefix)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#############################
#  Detailed security rules  #
#############################

resource "azurerm_network_security_rule" "custom_rules" {
  count                       = length(var.custom_rules)
  name                        = lookup(var.custom_rules[count.index], "name", "default_rule_name")
  priority                    = lookup(var.custom_rules[count.index], "priority")
  direction                   = lookup(var.custom_rules[count.index], "direction", "Any")
  access                      = lookup(var.custom_rules[count.index], "access", "Allow")
  protocol                    = lookup(var.custom_rules[count.index], "protocol", "*")
  source_port_ranges          = length(split(",", lookup(var.custom_rules[count.index], "source_port_range", "*"))) > 1 ? split(",", replace(lookup(var.custom_rules[count.index], "source_port_range", "*"), "*", "0-65535")) : null
  source_port_range           = length(split(",", lookup(var.custom_rules[count.index], "source_port_range", "*"))) == 1 ? lookup(var.custom_rules[count.index], "source_port_range", "*") : null
  destination_port_ranges     = length(split(",", lookup(var.custom_rules[count.index], "destination_port_range", "*"))) > 1 ? split(",", replace(lookup(var.custom_rules[count.index], "destination_port_range", "*"), "*", "0-65535")) : null
  destination_port_range      = length(split(",", lookup(var.custom_rules[count.index], "destination_port_range", "*"))) == 1 ? lookup(var.custom_rules[count.index], "destination_port_range", "*") : null
  # Only one source_address_prefixes, source_address_prefix, or source_application_security_group_ids may be used
  ## If we pass in a multi-valued CSV for source_address_prefix, use source_address_prefixes and split into a list
  source_address_prefixes     = length(split(",", lookup(var.custom_rules[count.index], "source_address_prefix", "*"))) > 1 ? split(",", lookup(var.custom_rules[count.index], "source_address_prefix", "*")) : null
  ## If we pass in a source_application_security_group_ids parameter and If we pass in a multi-valued CSV for source_address_prefix, use source_address_prefixes and split into a list
  source_address_prefix       = lookup(var.custom_rules[count.index], "source_application_security_group_ids", "") == "" && length(split(",", lookup(var.custom_rules[count.index], "source_address_prefix", "*"))) == 1 ? lookup(var.custom_rules[count.index], "source_address_prefix", "*") : null
  source_application_security_group_ids = lookup(var.custom_rules[count.index], "source_application_security_group_ids", "") == "" ? null : split(",", lookup(var.custom_rules[count.index], "source_application_security_group_ids", ""))
  destination_address_prefix  = lookup(var.custom_rules[count.index], "destination_address_prefix", "*")
  description                 = lookup(var.custom_rules[count.index], "description", "Security rule for ${lookup(var.custom_rules[count.index], "name", "default_rule_name")}")
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
