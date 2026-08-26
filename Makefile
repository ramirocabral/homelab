TF := terraform -chdir=terraform

.PHONY: help fmt validate plan apply inventory deps ping site labels

help:
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/' | expand -t20

fmt: ## Format all Terraform files
	$(TF) fmt -recursive

validate: ## Check the Terraform configuration is valid
	$(TF) validate

plan: ## Show what Terraform would change (read-only)
	$(TF) plan

apply: ## Apply the Terraform plan
	$(TF) apply

inventory: ## Regenerate ansible/inventory.ini from the Terraform fleet
	$(TF) apply -target=local_file.ansible_inventory

deps: ## Install the Ansible collections the playbook needs
	cd ansible && ansible-galaxy collection install -r requirements.yml

ping: ## Check every k3s node answers over SSH
	cd ansible && ansible -m ping all

site: ## Bootstrap the k3s cluster on the provisioned VMs
	cd ansible && ansible-playbook site.yml

labels: ## Reconcile the k3s node labels from the Terraform fleet
	$(TF) apply -target=local_file.ansible_inventory
	cd ansible && ansible-playbook site.yml --tags labels
