output "pbs_storage_id" {
  description = "PVE storage id backed by the PBS on TrueNAS"
  value       = proxmox_storage_pbs.truenas.id
}

output "k3s_nodes" {
  description = "k3s node name -> static IPv4"
  value       = { for name, m in module.k3s_node : name => m.ipv4_address }
}

output "vms" {
  description = "Standalone VM name -> static IPv4 (null when DHCP)"
  value       = { for name, m in module.vm : name => m.ipv4_address }
}

output "containers" {
  description = "LXC name -> static IPv4 (null when DHCP)"
  value       = { for name, m in module.lxc : name => m.ipv4_address }
}
