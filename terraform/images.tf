# The local datastore is per-node, so every node running containers needs its
# own copy of the template.
resource "proxmox_download_file" "lxc_template" {
  for_each = toset(values(local.container_node))

  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = each.key
  url          = var.lxc_template_url
}
