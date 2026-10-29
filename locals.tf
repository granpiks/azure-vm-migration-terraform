locals {
  # Naming convention: <project>-<environment>-<resource>
  name_prefix = "${var.project_name}-${var.environment}"

  # Mandatory tags, enforced by the deny policy in policy.tf.
  common_tags = merge(var.tags, {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  })

  windows_vms = { for k, v in var.vms : k => v if v.os_type == "Windows" }
  linux_vms   = { for k, v in var.vms : k => v if v.os_type == "Linux" }

  # flatten() turns the nested VM -> disk sizes structure into a flat map,
  # so each data disk is its own for_each instance with a stable key.
  data_disks = {
    for d in flatten([
      for vm_key, vm in var.vms : [
        for idx, size_gb in vm.data_disks_gb : {
          key     = "${vm_key}-disk${idx}"
          vm_key  = vm_key
          size_gb = size_gb
          lun     = idx
          owner   = vm.owner
        }
      ]
    ]) : d.key => d
  }
}
