# Guests join the nightly PBS backup by being in this pool. Nothing about the
# job itself changes when the fleet grows.
resource "proxmox_virtual_environment_pool" "prod" {
  pool_id = var.backup_pool
  comment = "Production guests"
}

resource "proxmox_storage_pbs" "truenas" {
  id        = "pbs-truenas"
  server    = var.pbs_server
  datastore = var.pbs_datastore

  username    = var.pbs_username
  password    = var.pbs_password
  fingerprint = var.pbs_fingerprint

  content = ["backup"]
}

# Retention is inherited from the PBS storage, not redefined here.
resource "proxmox_backup_job" "pool" {
  id       = "prod-backup"
  storage  = proxmox_storage_pbs.truenas.id
  pool     = proxmox_virtual_environment_pool.prod.pool_id
  schedule = var.backup_schedule
  mode     = "snapshot"
}
