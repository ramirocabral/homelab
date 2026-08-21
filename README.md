# lab

Homelab infrastructure: the code that creates and configures the VMs, the LXC containers
and the k3s cluster on Proxmox.

The applications running *inside* the cluster are not here — they live in
[`homelab-gitops`](https://github.com/ramirocabral/homelab-gitops), which Argo CD syncs.

## Layout

```
terraform/   Provisioning on Proxmox: VMs, LXCs, resource pool, PBS backups
ansible/     k3s bootstrap on the VMs Terraform creates
scripts/     Builds the Debian 13 cloud-init template on the PVE node
proxy/       nginx + certbot DNS-01 in the proxy LXC, for appliances outside the cluster
unifi/       Docker Compose for the UniFi Network Application, on its own VM
```

## Bringing it up, in order

**1. Base template.** Once, and again whenever you want to rebase the image:

```bash
ssh root@pve "CI_PASSWORD='...' SSH_PUBKEY='$(cat ~/.ssh/id_ed25519.pub)' bash -s" \
  < scripts/build-debian13-template.sh
```

**2. Provisioning.** Copy `terraform/terraform.tfvars.example` to `terraform.tfvars` and
fill in the secrets. Everything that isn't a secret already lives in
`terraform/fleet.auto.tfvars`.

```bash
make plan     # review first
make apply
```

Terraform also writes `ansible/inventory.ini` from the nodes it provisions.

**3. k3s cluster.**

```bash
make deps
make ping
make site
```

Leaves the kubeconfig at `ansible/kubeconfig` (not committed).

**4. Add-ons and applications.** Cilium, Longhorn, ingress-nginx and cert-manager are
installed after the playbook — see `ansible/README.md`. From there on, Argo CD is in charge.

## Services outside the cluster

Some services don't live in k8s but are still provisioned from here:

- **Technitium**: the lab's split-horizon DNS.
- **proxy**: nginx with Let's Encrypt certs over DNS-01, fronting appliances that
  only speak self-signed HTTPS (PVE, TrueNAS). See `proxy/`.
- **UniFi**: the AP controller, on Docker Compose. It sits outside
  k8s because it has to share the same L2 as the APs. See `unifi/`.

## Commands

```
make plan       show what Terraform would change (read-only)
make apply      apply it
make inventory  regenerate ansible/inventory.ini
make deps       install the Ansible collections
make ping       check the nodes answer over SSH
make site       bootstrap the k3s cluster
make fmt        format the Terraform files
make validate   validate the configuration
```

## Secrets

Nothing sensitive is committed. What stays out of the repo (see `.gitignore`):

| File | What it is |
|---|---|
| `terraform/terraform.tfvars` | Proxmox API token and PBS credentials |
| `terraform/*.tfstate*` | State, which stores those same values in cleartext |
| `ansible/kubeconfig` | k3s cluster-admin credential |
