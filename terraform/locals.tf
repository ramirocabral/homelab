locals {
  ssh_authorized_keys = [
    trimspace(file(var.ssh_public_key_path)),
  ]

  lab_resolver_ip = var.containers[var.lab_resolver].ip

  # Named resolver profiles a guest can pick from:
  #   lab      -> lab DNS first, public upstreams as fallback
  #   upstream -> public upstreams only (the lab resolver itself)
  #   host     -> inherit whatever the PVE host hands down
  resolvers = {
    lab      = concat([local.lab_resolver_ip], var.dns_fallback_servers)
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

  valid_resolvers = keys(local.resolvers)
}
