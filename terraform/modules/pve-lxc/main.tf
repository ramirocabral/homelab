terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.111"
    }
  }
}

locals {
  is_static = var.ipv4_address != null
}

resource "proxmox_virtual_environment_container" "this" {
  node_name    = var.node_name
  vm_id        = var.vm_id
  unprivileged = var.unprivileged
  tags         = var.tags
  pool_id      = var.pool_id
  started      = var.started

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  network_interface {
    name   = var.network_interface_name
    bridge = var.network_bridge
  }

  dynamic "features" {
    for_each = var.nesting ? [1] : []
    content {
      nesting = true
    }
  }

  initialization {
    hostname = var.name

    dynamic "dns" {
      for_each = length(var.dns_servers) > 0 ? [1] : []
      content {
        servers = var.dns_servers
      }
    }

    ip_config {
      ipv4 {
        address = local.is_static ? "${var.ipv4_address}/${var.ipv4_prefix}" : "dhcp"
        gateway = local.is_static ? var.gateway : null
      }
    }

    user_account {
      keys = var.ssh_keys
    }
  }

  lifecycle {
    ignore_changes = [pool_id, features]
  }
}
