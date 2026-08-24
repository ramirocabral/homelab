pve_endpoint = "https://192.168.9.7:8006/"
node_name    = "pve"
pve_nodes    = ["pve", "pve02"]
lan_gateway  = "192.168.9.1"

ssh_user            = "ramiro"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

vm_template_id   = 9000
lxc_template_url = "http://download.proxmox.com/images/system/debian-13-standard_13.6-1_amd64.tar.zst"

dns_fallback_servers = ["1.1.1.1", "9.9.9.9"]
lab_resolvers        = ["ns1", "ns2"]

pbs_server      = "192.168.9.50"
backup_pool     = "prod"
backup_schedule = "02:00"

# ---- LXC containers ---------------------------------------------------------

containers = {
  proxy = {
    vm_id    = 110
    cores    = 1
    memory   = 512
    disk     = 4
    resolver = "host"
    tags     = ["proxy"]
  }

  ns1 = {
    vm_id    = 111
    cores    = 1
    memory   = 1024
    disk     = 4
    ip       = "192.168.9.53"
    resolver = "upstream"
    tags     = ["dns"]
  }

  ns2 = {
    vm_id    = 113
    node     = "pve02"
    cores    = 1
    memory   = 1024
    disk     = 4
    ip       = "192.168.9.54"
    resolver = "upstream"
    tags     = ["dns"]
  }
}

# ---- Standalone VMs ---------------------------------------------------------

vms = {
  unifi = {
    vm_id   = 112
    cores   = 2
    node    = "pve02"
    memory  = 4096
    os_disk = 20
    ip      = "192.168.9.55"
    tags    = ["unifi"]
  }
}

# ---- k3s cluster ------------------------------------------------------------

k3s_nodes = {
  master01 = {
    vm_id   = 121
    ip      = "192.168.9.21"
    cores   = 2
    memory  = 6144
    os_disk = 20
    role    = "server"
    taint   = true
  }

  worker01 = {
    vm_id     = 122
    ip        = "192.168.9.22"
    cores     = 2
    memory    = 8192
    os_disk   = 20
    data_disk = 50
    role      = "agent"
  }

  worker02 = {
    vm_id     = 123
    node      = "pve02"
    ip        = "192.168.9.23"
    cores     = 2
    memory    = 8192
    os_disk   = 20
    data_disk = 50
    role      = "agent"
  }
}
