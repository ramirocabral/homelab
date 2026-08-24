variable "name" {
  type        = string
  description = "Container name, used as the cloud-init hostname"
}

variable "node_name" {
  type        = string
  description = "PVE node to run the container on"
}

variable "vm_id" {
  type        = number
  description = "Proxmox vmid"
}

variable "template_file_id" {
  type        = string
  description = "Datastore id of the OS template (vztmpl) to create the container from"
}

variable "os_type" {
  type        = string
  description = "Container OS type as understood by PVE"
  default     = "debian"
}

variable "cores" {
  type        = number
  description = "vCPU cores"
  default     = 1
}

variable "memory" {
  type        = number
  description = "RAM in MiB"
  default     = 512
}

variable "swap" {
  type        = number
  description = "Swap in MiB"
  default     = 512
}

variable "disk_size" {
  type        = number
  description = "Root disk size in GiB"
  default     = 4
}

variable "datastore_id" {
  type        = string
  description = "Datastore for the root disk"
  default     = "local-lvm"
}

variable "unprivileged" {
  type        = bool
  description = "Run as an unprivileged container"
  default     = true
}

variable "nesting" {
  type        = bool
  description = "Enable the nesting feature flag. Applied at creation only: changing flags later needs root@pam, so updates are ignored"
  default     = false
}

variable "started" {
  type        = bool
  description = "Start the container after creation"
  default     = true
}

variable "network_interface_name" {
  type        = string
  description = "Name of the container network interface"
  default     = "eth0"
}

variable "network_bridge" {
  type        = string
  description = "PVE bridge to attach the interface to"
  default     = "vmbr0"
}

variable "ipv4_address" {
  type        = string
  description = "Static IPv4 without prefix (e.g. 192.168.9.53). null = DHCP"
  default     = null
}

variable "ipv4_prefix" {
  type        = number
  description = "IPv4 prefix length for the static address"
  default     = 24
}

variable "gateway" {
  type        = string
  description = "Default gateway, only used with a static ipv4_address"
  default     = null
}

variable "dns_servers" {
  type        = list(string)
  description = "cloud-init DNS resolvers; empty = inherit from the host"
  default     = []
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys authorized for root in the container"
}

variable "pool_id" {
  type        = string
  description = "Resource pool to place the container in; null = none"
  default     = null
}

variable "tags" {
  type        = list(string)
  description = "Proxmox tags"
  default     = []
}
