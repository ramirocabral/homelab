module "vm" {
  source   = "./modules/pve-vm"
  for_each = var.vms

  name        = each.key
  node_name   = var.node_name
  vm_id       = each.value.vm_id
  template_id = var.vm_template_id

  cores            = each.value.cores
  memory           = each.value.memory
  os_disk_size     = each.value.os_disk
  additional_disks = each.value.data_disks

  ipv4_address = each.value.ip
  gateway      = var.lan_gateway
  dns_servers  = local.resolvers[each.value.resolver]

  ssh_keys      = local.ssh_authorized_keys
  username      = var.ssh_user
  pool_id       = proxmox_virtual_environment_pool.prod.pool_id
  tags          = concat(local.base_tags, each.value.tags)
  agent_enabled = true
}
