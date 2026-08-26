terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.111"
    }
  }
}

locals {
  # scsi0 is the root disk; extra data disks follow as scsi1, scsi2, ...
  disks = concat([var.os_disk_size], var.additional_disks)
  # true when a static address was given (vs DHCP).
  is_static = var.ipv4_address != null
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id
  migrate   = var.migrate
  tags      = var.tags
  pool_id   = var.pool_id

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  agent {
    enabled = var.agent_enabled
  }

  # scsi0 (root) + any additional data disks, all raw thin on the datastore.
  dynamic "disk" {
    for_each = { for i, size in local.disks : i => size }
    content {
      datastore_id = var.datastore_id
      interface    = "scsi${disk.key}"
      size         = disk.value
      discard      = "on"
      ssd          = true
    }
  }

  initialization {
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
      username = var.username
      keys     = var.ssh_keys
    }
  }

  serial_device {}

  # avoid destroying vm when pool_id changes
  lifecycle {
    ignore_changes = [pool_id, hostpci, vga, clone]
  }
}
