resource "proxmox_download_file" "lxc_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = var.node_name
  url          = var.lxc_template_url
}
