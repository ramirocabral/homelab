output "vm_id" {
  description = "Proxmox vmid of the VM"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.this.name
}

output "ipv4_address" {
  description = "Static IPv4 configured (null if DHCP)"
  value       = var.ipv4_address
}
