module "k3s_node" {
  source   = "./modules/pve-vm"
  for_each = var.k3s_nodes

  name        = "k3s-${each.key}"
  node_name   = local.k3s_node[each.key]
  vm_id       = each.value.vm_id
  template_id = var.vm_template_ids[local.k3s_node[each.key]]

  cores            = each.value.cores
  memory           = each.value.memory
  os_disk_size     = each.value.os_disk
  additional_disks = each.value.data_disk != null ? [each.value.data_disk] : []

  ipv4_address = each.value.ip
  gateway      = var.lan_gateway
  dns_servers  = local.resolvers["lab"]

  ssh_keys      = local.ssh_authorized_keys
  username      = var.ssh_user
  pool_id       = proxmox_virtual_environment_pool.prod.pool_id
  tags          = ["terraform", "k3s", each.value.role]
  agent_enabled = true
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    nodes        = var.k3s_nodes
    labels       = local.k3s_labels
    label_domain = var.node_label_domain
    ssh_user     = var.ssh_user
    server_ip    = one([for n in var.k3s_nodes : n.ip if n.role == "server"])
  })
}
