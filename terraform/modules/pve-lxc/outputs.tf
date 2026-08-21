output "vm_id" {
  description = "Proxmox vmid of the container"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "name" {
  description = "Container hostname"
  value       = var.name
}

output "ipv4_address" {
  description = "Static IPv4 configured (null if DHCP)"
  value       = var.ipv4_address
}
