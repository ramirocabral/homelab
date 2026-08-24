# Schema only. Concrete values live in fleet.auto.tfvars (lab facts, committed)
# and terraform.tfvars (credentials, gitignored).

# ---- Proxmox API ------------------------------------------------------------

variable "pve_endpoint" {
  type        = string
  description = "Proxmox API URL"
}

variable "pve_api_token" {
  type        = string
  description = "API token in USER@REALM!TOKENID=SECRET format"
  sensitive   = true
}

variable "node_name" {
  type        = string
  description = "Default PVE node for guests that do not pin one"
}

variable "pve_nodes" {
  type        = list(string)
  description = "PVE nodes in the cluster; a guest node must be one of these"
}

# ---- Guest defaults ---------------------------------------------------------

variable "vm_template_id" {
  type        = number
  description = "vmid of the cloud-init VM template to full-clone"
}

variable "lxc_template_url" {
  type        = string
  description = "URL of the LXC root filesystem template (vztmpl) to download"
}

variable "ssh_user" {
  type        = string
  description = "cloud-init user baked into the VM template, also the Ansible SSH user"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key injected into every guest"
}

variable "lan_gateway" {
  type        = string
  description = "Default gateway for the LAN"
}

variable "dns_fallback_servers" {
  type        = list(string)
  description = "Public resolvers, used behind the lab resolver and by the lab resolver itself"
}

variable "lab_resolvers" {
  type        = list(string)
  description = "Keys in var.containers of the containers running the lab DNS, in preference order"
}

# ---- Fleet ------------------------------------------------------------------

variable "containers" {
  type = map(object({
    vm_id    = number
    node     = optional(string)
    cores    = optional(number, 1)
    memory   = optional(number, 512)
    swap     = optional(number, 512)
    disk     = optional(number, 4)
    ip       = optional(string)        # null = DHCP
    resolver = optional(string, "lab") # lab | upstream | host
    nesting  = optional(bool, false)
    tags     = optional(list(string), [])
  }))
  description = "LXC containers, keyed by hostname"
}

variable "vms" {
  type = map(object({
    vm_id      = number
    node       = optional(string)
    cores      = optional(number, 2)
    memory     = optional(number, 2048)
    os_disk    = optional(number, 20)
    data_disks = optional(list(number), [])
    ip         = optional(string)        # null = DHCP
    resolver   = optional(string, "lab") # lab | upstream | host
    tags       = optional(list(string), [])
  }))
  description = "Standalone VMs, keyed by hostname"
}

variable "k3s_nodes" {
  type = map(object({
    vm_id     = number
    node      = optional(string)
    ip        = string
    cores     = optional(number, 2)
    memory    = optional(number, 4096)
    os_disk   = optional(number, 20)
    data_disk = optional(number) # GiB on scsi1 for Longhorn; null = none
    role      = string           # server | agent
    taint     = optional(bool, false)
  }))
  description = "k3s cluster nodes, keyed by node name"

  validation {
    condition     = length([for n in var.k3s_nodes : n if n.role == "server"]) == 1
    error_message = "Exactly one node must have role \"server\" (single control-plane for now)."
  }

  validation {
    condition     = alltrue([for n in var.k3s_nodes : contains(["server", "agent"], n.role)])
    error_message = "Node role must be either \"server\" or \"agent\"."
  }
}

# ---- Proxmox Backup Server --------------------------------------------------

variable "pbs_server" {
  type        = string
  description = "PBS address as reachable from the PVE node"
}

variable "pbs_datastore" {
  type        = string
  description = "Datastore name on the PBS side"
}

variable "pbs_fingerprint" {
  type        = string
  description = "SHA256 fingerprint of the self-signed PBS TLS certificate"
}

variable "pbs_username" {
  type        = string
  description = "PBS auth identity. API token form: user@realm!tokenid"
}

variable "pbs_password" {
  type        = string
  description = "PBS password, or the API token secret when username is a token"
  sensitive   = true
}

variable "backup_pool" {
  type        = string
  description = "Resource pool whose guests are backed up nightly to PBS"
}

variable "backup_schedule" {
  type        = string
  description = "Backup job schedule in systemd calendar format"
}
