resource "azurerm_network_interface" "vm" {
  for_each = var.vms

  name                = "${local.name_prefix}-${each.key}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(local.common_tags, { owner = each.value.owner })

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = each.value.private_ip != null ? "Static" : "Dynamic"
    private_ip_address            = each.value.private_ip
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = local.windows_vms

  name                  = "${local.name_prefix}-${each.key}"
  computer_name         = substr(each.key, 0, 15)
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = each.value.size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm[each.key].id]

  tags = merge(local.common_tags, {
    owner          = each.value.owner
    migration_wave = tostring(each.value.migration_wave)
  })

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    precondition {
      condition     = var.admin_password != null
      error_message = "admin_password is required when at least one Windows VM is declared."
    }
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.linux_vms

  name                  = "${local.name_prefix}-${each.key}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = each.value.size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm[each.key].id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  tags = merge(local.common_tags, {
    owner          = each.value.owner
    migration_wave = tostring(each.value.migration_wave)
  })

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    precondition {
      condition     = var.admin_ssh_public_key != null
      error_message = "admin_ssh_public_key is required when at least one Linux VM is declared."
    }
  }
}

locals {
  vm_ids = merge(
    { for k, v in azurerm_windows_virtual_machine.vm : k => v.id },
    { for k, v in azurerm_linux_virtual_machine.vm : k => v.id },
  )
}

resource "azurerm_managed_disk" "data" {
  for_each = local.data_disks

  name                 = "${local.name_prefix}-${each.key}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  tags                 = merge(local.common_tags, { owner = each.value.owner })
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = local.data_disks

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = local.vm_ids[each.value.vm_key]
  lun                = each.value.lun
  caching            = "ReadOnly"
}
