# Azure VM migration with Terraform

Terraform template to land a wave of on-premises VMs in an Azure landing zone, with governance deployed alongside the workloads.

The whole inventory of a migration wave is one map. Adding a VM means adding an entry to `vms`, never copying a resource block.

## Design choices

- **`for_each` over a single inventory map.** NICs, Windows VMs, Linux VMs, data disks and their attachments are each declared once and generated from `var.vms`. Stable map keys mean removing one VM never shifts or recreates the others, which `count` would.
- **Windows and Linux in the same wave.** The map is split by `os_type` into two `for_each` sets, one per azurerm VM resource.
- **Flattened data disks.** `flatten()` turns the VM → disk sizes structure into one flat map, so each disk and its attachment get a stable key (`db01-disk1`) and their LUN.
- **Policy as code from day one.** A custom deny policy enforces the mandatory tags (`project`, `environment`, `owner`) and the built-in *Allowed locations* policy pins deployments to the target region. Both are assigned at resource group scope by Terraform, not clicked in the portal afterwards.
- **Fail early.** Input validation on `environment` and `os_type`, and lifecycle preconditions that stop the plan when a Windows VM has no admin password or a Linux VM has no SSH key.
- **No secrets in code.** The Windows password is a sensitive variable passed through `TF_VAR_admin_password` (pipeline or Key Vault). Linux VMs are SSH-key only. Every VM gets a system-assigned managed identity.
- **Cutover-ready outputs.** `vms_by_wave` groups VMs by migration wave and `vm_private_ips` feeds the cutover checklist (DNS, firewall rules).

## Layout

| File | Content |
|---|---|
| `versions.tf` | Terraform and azurerm versions, remote backend, provider |
| `variables.tf` | Inputs and the `vms` inventory map, with validation |
| `locals.tf` | Naming convention, mandatory tags, OS split, flattened data disks |
| `vm.tf` | NICs, Windows and Linux VMs, data disks and attachments |
| `policy.tf` | Tag enforcement and allowed locations, at resource group scope |
| `outputs.tf` | VM IDs, private IPs, VMs grouped by wave |
| `examples/terraform.tfvars.example` | A three-VM, two-wave example |

## Usage

Prerequisites: an existing resource group and subnet in the landing zone.

```bash
cp examples/terraform.tfvars.example terraform.tfvars   # then fill in the real inventory
export TF_VAR_admin_password='...'                        # only if the wave has Windows VMs
terraform init
terraform plan -out wave.tfplan
terraform apply wave.tfplan
```

For a real migration, enable the `azurerm` backend in `versions.tf` so the state is remote and locked.

CI runs `terraform fmt -check` and `terraform validate` on every push.

## License

MIT
