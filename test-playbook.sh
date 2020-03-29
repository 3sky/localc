#!/bin/bash

# Run terraform
terraform init
terraform apply -auto-approve

# Run role
ANSIBLE_HOST_KEY_CHECKING=False ansible -i inventory.gcp.yaml ansible-test-machine  -m include_role -a name=basic-https-server -u kuba -b

# Run test
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.gcp.yaml basic-https-server/tests/test.yml

# Delete Infra after tests
terraform destroy -auto-approve