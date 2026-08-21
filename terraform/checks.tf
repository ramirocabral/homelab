check "unique_vm_ids" {
  assert {
    condition     = length(local.fleet_vm_ids) == length(distinct(local.fleet_vm_ids))
    error_message = "Duplicate vm_id across containers / vms / k3s_nodes in fleet.auto.tfvars."
  }
}

check "unique_ips" {
  assert {
    condition     = length(local.fleet_ips) == length(distinct(local.fleet_ips))
    error_message = "Duplicate static IPv4 across containers / vms / k3s_nodes in fleet.auto.tfvars."
  }
}

check "known_resolvers" {
  assert {
    condition = alltrue(concat(
      [for c in var.containers : contains(local.valid_resolvers, c.resolver)],
      [for v in var.vms : contains(local.valid_resolvers, v.resolver)],
    ))
    error_message = "resolver must be one of: ${join(", ", local.valid_resolvers)}."
  }
}

check "lab_resolver_is_static" {
  assert {
    condition     = local.lab_resolver_ip != null
    error_message = "The container named by var.lab_resolver needs a static ip; other guests point their DNS at it."
  }
}
