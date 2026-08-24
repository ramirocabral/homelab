module "lxc" {
  source   = "./modules/pve-lxc"
  for_each = var.containers

  name             = each.key
  node_name        = local.container_node[each.key]
  vm_id            = each.value.vm_id
  template_file_id = proxmox_download_file.lxc_template[local.container_node[each.key]].id

  cores     = each.value.cores
  memory    = each.value.memory
  swap      = each.value.swap
  disk_size = each.value.disk
  nesting   = each.value.nesting

  ipv4_address = each.value.ip
  gateway      = var.lan_gateway
  dns_servers  = local.resolvers[each.value.resolver]

  ssh_keys = local.ssh_authorized_keys
  pool_id  = proxmox_virtual_environment_pool.prod.pool_id
  tags     = concat(local.base_tags, each.value.tags)
}
