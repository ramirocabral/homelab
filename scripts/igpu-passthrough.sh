set -euo pipefail

IGD_ADDR="${IGD_ADDR:-0000:00:02.0}"
CMDLINE_ARGS="intel_iommu=on iommu=pt initcall_blacklist=sysfb_init"

die() { echo "!! $*" >&2; exit 1; }

igd_id() {
  lspci -n -s "$IGD_ADDR" | awk '{print $3}'
}

prepare_host() {
  [ -d /sys/kernel/iommu_groups ] && [ -n "$(ls -A /sys/kernel/iommu_groups)" ] \
    || die "no IOMMU groups: enable VT-d in the BIOS first"

  local id group
  id="$(igd_id)" || die "no PCI device at $IGD_ADDR"
  [ -n "$id" ] || die "no PCI device at $IGD_ADDR"
  group="$(readlink -f "/sys/bus/pci/devices/$IGD_ADDR/iommu_group")"
  echo ">> iGPU at $IGD_ADDR is $id, IOMMU group ${group##*/}"
  [ "$(ls "$group/devices" | wc -l)" -eq 1 ] \
    || die "IOMMU group ${group##*/} holds more devices than the iGPU; they would all have to move together"

  echo ">> binding $id to vfio-pci on boot"
  cat > /etc/modprobe.d/vfio-igpu.conf <<EOF
options vfio-pci ids=$id
softdep i915 pre: vfio-pci
blacklist i915
EOF

  cat > /etc/modules-load.d/vfio.conf <<'EOF'
vfio
vfio_iommu_type1
vfio-pci
EOF

  local current
  current="$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"$/\1/p' /etc/default/grub)"
  for arg in $CMDLINE_ARGS; do
    case " $current " in
      *" $arg "*) ;;
      *) current="$current $arg" ;;
    esac
  done
  echo ">> kernel cmdline: $current"
  sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$current\"|" /etc/default/grub

  update-grub
  update-initramfs -u -k all

  cat <<EOF

>> host prepared. Reboot it, then check the iGPU landed on vfio-pci:

     reboot
     lspci -nnk -s $IGD_ADDR | grep 'Kernel driver'   # -> vfio-pci

   After that, attach it to the VM:

     $0 attach <VMID>
EOF
}

attach_vm() {
  local vmid="${1:?usage: $0 attach <VMID>}"
  qm config "$vmid" >/dev/null 2>&1 || die "no VM $vmid on this node"

  local driver
  driver="$(lspci -nk -s "$IGD_ADDR" | sed -n 's/.*Kernel driver in use: //p')"
  [ "$driver" = "vfio-pci" ] || die "iGPU is on '$driver', not vfio-pci: run '$0 host' and reboot first"

  echo ">> stopping VM $vmid"
  qm stop "$vmid" || true
  while [ "$(qm status "$vmid")" != "status: stopped" ]; do sleep 2; done

  echo ">> attaching $IGD_ADDR to VM $vmid"
  qm set "$vmid" --hostpci0 "${IGD_ADDR%.*},rombar=0"

  echo ">> starting VM $vmid"
  qm start "$vmid"

  cat <<EOF

>> done. In the guest:

     ls -l /dev/dri            # renderD128
     sudo vainfo --display drm --device /dev/dri/renderD128
EOF
}

case "${1:-}" in
  host)   prepare_host ;;
  attach) shift; attach_vm "$@" ;;
  *)      die "usage: $0 host | $0 attach <VMID>" ;;
esac
