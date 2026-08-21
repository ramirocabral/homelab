moved {
  from = module.unifi
  to   = module.vm["unifi"]
}

moved {
  from = proxmox_virtual_environment_container.proxy
  to   = module.lxc["proxy"].proxmox_virtual_environment_container.this
}

moved {
  from = proxmox_virtual_environment_container.technitium
  to   = module.lxc["technitium"].proxmox_virtual_environment_container.this
}

moved {
  from = proxmox_download_file.debian13_ct
  to   = proxmox_download_file.lxc_template
}
