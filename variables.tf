variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "project_name" {
  description = "Short project name, used in resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Target environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Target Azure region. Also the only region allowed by policy.tf."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Existing resource group that receives the migrated VMs."
  type        = string
}

variable "subnet_id" {
  description = "ID of the landing zone subnet for this migration wave."
  type        = string
}

variable "admin_username" {
  description = "Local administrator account created on every VM."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Windows admin password. Injected by the CI/CD pipeline or Key Vault, never committed."
  type        = string
  sensitive   = true
  default     = null
}

variable "admin_ssh_public_key" {
  description = "SSH public key for Linux VMs."
  type        = string
  default     = null
}

# One entry = one VM to migrate. Adding a VM means adding an entry here,
# never a new resource block.
variable "vms" {
  description = "VMs to migrate, keyed by short VM name."
  type = map(object({
    size            = string
    os_type         = string
    os_disk_size_gb = number
    data_disks_gb   = optional(list(number), [])
    private_ip      = optional(string)
    owner           = string
    migration_wave  = number
  }))

  validation {
    condition     = alltrue([for vm in values(var.vms) : contains(["Windows", "Linux"], vm.os_type)])
    error_message = "os_type must be \"Windows\" or \"Linux\"."
  }
}

variable "tags" {
  description = "Extra tags merged into the mandatory tags of every resource."
  type        = map(string)
  default     = {}
}
