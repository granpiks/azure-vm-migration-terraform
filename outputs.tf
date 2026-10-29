output "vm_ids" {
  description = "Resource IDs of the created VMs."
  value       = local.vm_ids
}

output "vm_private_ips" {
  description = "Private IPs of the created VMs, for the cutover checklist."
  value       = { for k, nic in azurerm_network_interface.vm : k => nic.private_ip_address }
}

output "vms_by_wave" {
  description = "VM names grouped by migration wave, to drive cutover batch by batch."
  value = {
    for wave in distinct([for v in values(var.vms) : v.migration_wave]) :
    tostring(wave) => [for k, v in var.vms : k if v.migration_wave == wave]
  }
}
