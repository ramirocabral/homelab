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

**1. Base template**, one per PVE node that runs VMs, since a template on local storage cannot
be cloned across nodes and vmids are cluster-unique. Once, and again whenever you want to rebase
the image. The vmids have to match `vm_template_ids` in `terraform/fleet.auto.tfvars`:

```bash
ssh root@pve "CI_PASSWORD='...' SSH_PUBKEY='$(cat ~/.ssh/id_ed25519.pub)' bash -s" \
  < scripts/build-debian13-template.sh
ssh root@pve02 "VMID=9001 CI_PASSWORD='...' SSH_PUBKEY='$(cat ~/.ssh/id_ed25519.pub)' bash -s" \
  < scripts/build-debian13-template.sh
```

**2. Provisioning.** Copy `terraform/terraform.tfvars.example` to `terraform.tfvars` and
fill in the secrets. Everything that isn't a secret already lives in
`terraform/fleet.auto.tfvars`. The state lives in the `tfstate` bucket on Garage, so also copy
`terraform/backend.hcl.example` to `backend.hcl` with the bucket's key.

```bash
make init     # once per checkout
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

## Commands

```
make init       initialize Terraform against the Garage state backend
make plan       show what Terraform would change (read-only)
make apply      apply it
make inventory  regenerate ansible/inventory.ini
make deps       install the Ansible collections
make ping       check the nodes answer over SSH
make site       bootstrap the k3s cluster
make labels     reconcile the k3s node labels from the fleet
make fmt        format the Terraform files
make validate   validate the configuration
```
## Secrets

Nothing sensitive is committed. What stays out of the repo (see `.gitignore`):

| File | What it is |
|---|---|
| `terraform/terraform.tfvars` | Proxmox API token and PBS credentials |
| `terraform/backend.hcl` | Garage access key for the state bucket |
| `tfstate/lab/terraform.tfstate` on Garage | State, which stores those same values in cleartext |
| `ansible/kubeconfig` | k3s cluster-admin credential |

## Decisions

- **Terraform state on Garage (S3 backend), on the TrueNAS.** It lives outside everything this
  repo provisions: the `kubernetes` backend would put the state inside the cluster Terraform
  itself creates. Garage has no object versioning, so there is no state history. There is no
  state locking: Garage ignores the conditional writes
  `use_lockfile` relies on, so two concurrent runs both take the lock and the second one
  overwrites it. Acceptable with a single operator; don't run two `apply` at once.
