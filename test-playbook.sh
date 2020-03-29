#!/bin/bash

# Run terraform
terraform init
terraform apply -auto-approve

# Run role
ansible -i inventory.gcp.yaml node  -m include_role -a name=basic-https-server -u kuba -b

# Run test
ansible-playbook -i inventory.gcp.yaml basic-https-server/tests/test.yml

# Delete Infra after tests
terraform destroy -auto-approve