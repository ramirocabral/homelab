# Generic cloud-init VM cloned from a Proxmox template. Deliberately k3s-agnostic
# so it can back any Debian guest (k3s nodes, the test VM, future appliances).

variable "name" {
  type        = string
  description = "VM name (also used as the cloud-init guest hostname)"
}

variable "node_name" {
  type        = string
  description = "PVE node to run the VM on"
}

variable "vm_id" {
  type        = number
  description = "Proxmox vmid"
}

variable "template_id" {
  type        = number
  description = "vmid of the cloud-init template to full-clone"
}

variable "cores" {
  type        = number
  description = "vCPU cores"
  default     = 2
}

variable "cpu_type" {
  type        = string
  description = "QEMU CPU type"
  default     = "host"
}

variable "memory" {
  type        = number
  description = "RAM in MiB"
  default     = 2048
}

variable "os_disk_size" {
  type        = number
  description = "Root disk (scsi0) size in GiB; cloud-init growpart expands to it"
  default     = 20
}

variable "additional_disks" {
  type        = list(number)
  description = "Extra data disks in GiB, attached as scsi1, scsi2, ... (raw; format in Ansible)"
  default     = []
}

variable "datastore_id" {
  type        = string
  description = "Datastore for the disks"
  default     = "local-lvm"
}

variable "ipv4_address" {
  type        = string
  description = "Static IPv4 without prefix (e.g. 192.168.9.21). null = DHCP."
  default     = null
}

variable "ipv4_prefix" {
  type        = number
  description = "IPv4 prefix length for the static address"
  default     = 24
}

variable "gateway" {
  type        = string
  description = "Default gateway (only used with a static ipv4_address)"
  default     = null
}

variable "dns_servers" {
  type        = list(string)
  description = "cloud-init DNS resolvers; empty = inherit from the template"
  default     = []
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys authorized for the cloud-init user"
}

variable "username" {
  type        = string
  description = "cloud-init user (ciuser). Must match the user baked into the template, otherwise the provider shows a perpetual username diff and reboots the VM on every apply."
}

variable "pool_id" {
  type        = string
  description = "Resource pool to place the VM in; null = none"
  default     = null
}

variable "tags" {
  type        = list(string)
  description = "Proxmox tags"
  default     = []
}

variable "agent_enabled" {
  type        = bool
  description = "Enable the QEMU guest agent. Keep false until it's installed in-guest."
  default     = false
}
