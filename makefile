# Variáveis
TF_DIR := terraform

# terraform
init:
	cd $(TF_DIR) && terraform init

apply:
	sudo hwclock -s && cd $(TF_DIR) && terraform apply --auto-approve

destroy:
	sudo hwclock -s && cd $(TF_DIR) && terraform destroy --auto-approve

# Ansible
install-kubernetes:
	ansible-playbook -i inventory.yaml playbooks/install-kubernetes.yaml

setup-control-planes:
	ansible-playbook -i inventory.yaml playbooks/setup-control-planes.yaml

setup-workers:
	ansible-playbook -i inventory.yaml playbooks/setup-workers.yaml

# main
kubernetes: init apply install-kubernetes setup-control-planes setup-workers

.PHONY: init apply destroy install-kubernetes setup-control-planes setup-workers kubernetes
