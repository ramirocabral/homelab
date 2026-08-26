#!/usr/bin/env bash
#
# build-debian13-template.sh
# Builds a minimal Debian 13 (trixie) cloud-init VM template on Proxmox: base
# image + cloud-init + qemu-guest-agent, baked in so clones boot with the agent
# running and Terraform does not hang on the agent channel.
#
# Login is SSH key only; the cloud-init password is just for the noVNC console.
# Neither the key nor the password is stored in the repo.
#
# Run from the workstation:
#   ssh root@pve "CI_PASSWORD='...' SSH_PUBKEY='$(cat ~/.ssh/id_ed25519.pub)' bash -s" \
#     < scripts/build-debian13-template.sh
#
# VMID must match var.vm_template_id in terraform/fleet.auto.tfvars, and CIUSER
# must match var.ssh_user there.
#
set -euo pipefail

: "${CI_PASSWORD:?set CI_PASSWORD for the cloud-init user password}"
: "${SSH_PUBKEY:?set SSH_PUBKEY to the public key authorized for CIUSER}"

case "$SSH_PUBKEY" in
  ssh-*|ecdsa-*) ;;
  *) echo "SSH_PUBKEY is not a public key, it is: $SSH_PUBKEY" >&2; exit 1 ;;
esac

VMID="${VMID:-9000}"
NAME="${NAME:-debian-13-base}"
STORAGE="${STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"
CIUSER="${CIUSER:-ramiro}"
IMG="${IMG:-debian-13-generic-amd64.qcow2}"
URL="${URL:-https://cloud.debian.org/images/cloud/trixie/latest/${IMG}}"
WORKDIR="${WORKDIR:-/var/lib/vz/template/qcow}"

KEYFILE="$(mktemp)"
printf '%s\n' "$SSH_PUBKEY" > "$KEYFILE"
trap 'rm -f "$KEYFILE"' EXIT

mkdir -p "$WORKDIR"; cd "$WORKDIR"
# (Re)download if the image is missing or empty. Download to a .part file first
# so a failed/interrupted download never leaves a corrupt $IMG behind (which
# would make importdisk fail with "--virtualsize may not be zero").
if [ ! -s "$IMG" ]; then
  echo ">> downloading $IMG"
  rm -f "$IMG"
  wget -O "$IMG.part" "$URL"
  mv "$IMG.part" "$IMG"
fi

# Bake qemu-guest-agent into the image so cloned VMs boot with the agent already
# running. Without this, enabling the Proxmox agent channel (--agent enabled=1)
# leaves the guest service unable to start, and Terraform hangs on create waiting
# for an agent that isn't installed yet. Needs libguestfs-tools on the node.
if ! command -v virt-customize >/dev/null 2>&1; then
  echo ">> installing libguestfs-tools (for virt-customize)"
  # Don't gate the install on `apt-get update`: on a PVE node without a
  # subscription the enterprise repos return 401 and update exits non-zero, but
  # libguestfs-tools lives in Debian main and installs fine from the cached lists.
  apt-get update || true
  apt-get install -y libguestfs-tools
fi
echo ">> baking qemu-guest-agent into $IMG"
virt-customize -a "$IMG" --install qemu-guest-agent

# recreate the base VM
if qm status "$VMID" >/dev/null 2>&1; then
  echo ">> destroying existing template $VMID"
  qm destroy "$VMID" --purge
fi

qm create "$VMID" \
  --name "$NAME" \
  --ostype l26 \
  --cpu host \
  --cores 1 --sockets 1 \
  --memory 2048 \
  --numa 0 \
  --scsihw virtio-scsi-pci \
  --net0 virtio,bridge="$BRIDGE" \
  --serial0 socket --vga serial0 \
  --agent enabled=1

qm importdisk "$VMID" "$IMG" "$STORAGE"
qm set "$VMID" --scsi0 "${STORAGE}:vm-${VMID}-disk-0,discard=on,ssd=1"
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"
qm set "$VMID" --boot order=scsi0
qm set "$VMID" --ciuser "$CIUSER"
qm set "$VMID" --cipassword "$CI_PASSWORD"
qm set "$VMID" --sshkeys "$KEYFILE"
qm set "$VMID" --ipconfig0 ip=dhcp

# convert to template
qm template "$VMID"
echo ">> template $VMID ($NAME) ready: Debian 13, cloud-init, SSH key + console password"
