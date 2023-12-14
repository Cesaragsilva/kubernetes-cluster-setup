# Kubernetes Setup with Terraform and Ansible

This repository contains the necessary configuration files for setting up a basic Kubernetes cluster in AWS using Terraform and Ansible. The setup includes a control plane node and a worker node.

> [!CAUTION]
>
> This setup is not intended for production use, it is only for learning purposes.

> [!WARNING]
>
> The resources created by Terraform are not free. Make sure to destroy the resources after you finish your testing.

> [!NOTE]
>
> The instance type used in this setup are t4g.small (ARM64 architecture). It has a free tier (750/h per month) until 31/12/2023.

## Prerequisites

- Terraform installed
- Ansible installed
- AWS account with credentials configured

## Setup

1. Clone this repository.
2. Navigate to the repository directory.
3. Run Terraform to create the basic network configuration and nodes in AWS:

```bash
cd terraform
terraform init
terraform apply
```

1. After that, add the Terraform output hosts to the Ansible inventory.yaml file.

Terraform output:

```
aws_instances = [
  "0.0.0.0", # control plane node
  "0.0.0.0", # worker node
]
```

Ansible inventory.yaml:

```yaml
cluster:
  children:
    control_planes:
      hosts:
        cp:
          ansible_host: 0.0.0.0 # Control plane node IP
    workers:
      hosts:
        worker1:
          ansible_host: 0.0.0.0 # Worker node IP
```

6. Execute the following commands to setup the EC2 instances and local kubeconfig. It will take some time to finish.

```bash
# Go back to the root directory of the repository
cd ../

ansible-playbook -i inventory.yaml playbooks/install-kubernetes.yaml
ansible-playbook -i inventory.yaml playbooks/setup-control-planes.yaml
ansible-playbook -i inventory.yaml playbooks/setup-workers.yaml
```

7. Finally, you can check the nodes status by running:

```bash
kubectl get nodes
```

## Connect to the cluster

If you want to connect to ec2 instances via SSH, you can use the following command:

```bash
ssh -i ./terraform/externals/cp.pem ubuntu@<node-ip> # Change <node-ip> with the node IP (from Terraform output)
```

## Clean up

To clean up the resources created by Terraform, run:

```bash
cd terraform
terraform destroy
```
