+++
draft = true
date = 2020-03-29T22:55:02Z
title = "Ansible + Molecule - First Round"
description = "I would like to test my role"
slug = ""
tags = ["Ansible", "Molecule", "Docker"]
categories = ["tutorials"]
externalLink = ""
series = ["Ansible"]
+++

# Welcome

<!-- Why ?  -->

## Tools used in this episode

- Terraform
- Ansible
- Molecule


## Terraform

<!-- Why ?  -->

### Why Terraform

<!-- Why ?  -->

### Let's code - Terraform

1. As always I'll use GCP and Terraform
    I would like to add linter to automatic pipeline,
    so changes in `.github/workflows/main.yml` are mandatory.

    ```yaml {linenos=table}
    name: CI

    on: [push]

    jobs:
    build:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2
        - name: Run a one-line script
          run: echo Hello, world!
        - name: Install Hugo
          run: sudo snap install hugo
        - name: Install ruby-dev # Start test
          run: sudo ap-get install ruby-dev
        - name: Install rake and bundler
          run: sudo gem install rake bundler
        - name: Run tests
          run: mdl content/* # End of test
        - name: Run deploy.sh
          env:
            GH_TOKEN: ${{ secrets.GH_TOKEN }}
          run: sh ./deploy.sh
    ```

1. Create `.gitignore`.

    ```bash
    cat << EOF > .gitignore
    auth.json
    .terraform/
    terraform.*
    EOF
    ```

1. Init Terraform

    ```bash
    terraform init
    ```

1. Run terraform and create workstation

    ```bash
    terraform apply
    ```

1. Connect to instance via ssh

    ```bash
    ssh user@ip

    # user = form line `metadata` secion
    # ip = from `ip` variable output
    # Example
    # ssh kuba@35.123.25.1
    ```

1. Install vagrant and ansible on VM

    ```bash
    sudo apt install virtualbox
    ```

1. Add user to correct group

    ```bash
    wget https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.deb -O vagrant_2.2.7_x86_64.deb
    sudo apt install ./vagrant_2.2.7_x86_64.deb
    ```

1. Check installation

    ```bash
    vagrant --version
    ```

1. Install Ansible from PPA

    ```bash
    sudo apt update
    sudo apt install software-properties-common
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt install ansible
    ```

    ```bash
    sudo apt-get install python-pip
    pip install requests google-auth

    # /etc/ansible/ansible.cfg
    [inventory]
    enable_plugins = gcp_compute

    mkdir ansible
    cd ansible
    ```


1. Check installation

    ```bash
    ansible --version
    ```

1. Install Molecule

    ```bash
    sudo apt-get install python pip
    pip install molecule python-vagrant molecule-vagrant
    ```

1. Check installation

    ```bash
    molecule --version
    ```

1. Re-login to apply changes

## Let's Ansible

1. Init basic role

    ```bash
    molecule init role --driver-name vagrat basic-https-server
    ```

1. File structure

    ```bash
    # tree basic-https-server
    basic-https-server
    ├── README.md
    ├── defaults
    │   └── main.yml
    ├── files
    ├── handlers
    │   └── main.yml
    ├── meta
    │   └── main.yml
    ├── molecule
    │   └── default
    │       ├── INSTALL.rst
    │       ├── converge.yml
    │       ├── molecule.yml
    │       └── verify.yml
    ├── tasks
    │   └── main.yml
    ├── templates
    ├── tests
    │   ├── inventory
    │   └── test.yml
    └── vars
        └── main.yml

    10 directories, 12 files
    ```

1. Init boxes

    ```bash
    vagrant init bento/centos-7.7
    vagrant up
    ```

1. Try test

    ```bash
    molecule test
    ```

1. Local test

    ```bash
    ansible -i inventory.gcp.yaml node  -m include_role -a name=basic-https-server
    ```