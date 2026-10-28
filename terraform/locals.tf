locals {
  ssh_authorized_keys = [
    trimspace(file(var.ssh_public_key_path)),
  ]

  # PVE node each guest lands on; null in the fleet means var.node_name.
  container_node = { for k, c in var.containers : k => coalesce(c.node, var.node_name) }
  vm_node        = { for k, v in var.vms : k => coalesce(v.node, var.node_name) }
  k3s_node       = { for k, n in var.k3s_nodes : k => coalesce(n.node, var.node_name) }

  k3s_labels = {
    for k, n in var.k3s_nodes : k => merge(
      { "${var.node_label_domain}/pve-node" = local.k3s_node[k] },
      { for lk, lv in n.labels : "${var.node_label_domain}/${lk}" => lv },
    )
  }

  lab_resolver_ips = [for k in var.lab_resolvers : var.containers[k].ip]

  # Named resolver profiles a guest can pick from:
  #   lab      -> lab DNS only; resolved treats every listed server as equivalent and
  #               sticks to a public one after a failover, losing the internal zone
  #   upstream -> public upstreams only (the lab resolvers themselves)
  #   host     -> inherit whatever the PVE host hands down
  resolvers = {
    lab      = local.lab_resolver_ips
    upstream = var.dns_fallback_servers
    host     = []
  }

  base_tags = ["terraform", "infra"]

  fleet_vm_ids = concat(
    [for c in var.containers : c.vm_id],
    [for v in var.vms : v.vm_id],
    [for n in var.k3s_nodes : n.vm_id],
  )

  fleet_ips = compact(concat(
    [for c in var.containers : c.ip],
    [for v in var.vms : v.ip],
    [for n in var.k3s_nodes : n.ip],
  ))

  fleet_nodes = distinct(concat(
    values(local.container_node),
    values(local.vm_node),
    values(local.k3s_node),
  ))

  valid_resolvers = keys(local.resolvers)
}
