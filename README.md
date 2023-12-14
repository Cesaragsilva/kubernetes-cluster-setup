# Kubernetes Setup with Terraform and Ansible

This repository contains the necessary configuration files for setting up a basic Kubernetes cluster in AWS using Terraform and Ansible. The setup includes a control plane node and a worker node.

> [!CAUTION]
>
> This setup is not intended for production use, it is only for learning purposes.

> [!WARNING]
>
> The resources created by Terraform are not free. Make sure to destroy the resources after you finish your testing.

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

1. After that, add the Terraform output hosts to the Ansible inventory.yaml file. It would be like:

```
<!-- terraform output: -->
aws_instances = [
  "0.0.0.0", # control plane node
  "0.0.0.0", # worker node
]
```

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

1. Finally, you can check the nodes status by running:

```bash
kubectl get nodes
```

## Connect to the cluster

If you want to connect to ec2 instances, you can use the following commands:

```bash
ssh -i ./terraform/externals/cp.pem ubuntu@<node-ip> # Change <node-ip> with the node IP (from Terraform output)
```

## Clean up

To clean up the resources created by Terraform, run:

```bash
cd terraform
terraform destroy
```
