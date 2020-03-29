# Welcome

<!-- Why ?  -->

## Tools used in this episode

- Ansible
- Molecule
- Vagrant
- Terraform
- Bash

## Install Ansible

1. Install Ansible from PPA

    ```bash
    sudo apt update
    sudo apt install software-properties-common
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt install ansible
    ```

## First try with Molecule

1. Start with docker on VM

    ```bash
    sudo apt install docker.io
    ```

1. Add user to correct group

    ```bash
    sudo usermod -aG docker $USER
    ```

1. Re-login to apply changes

1. Check installation

    ```bash
    docker info
    ```

1. Install Molecule

    ```bash
    sudo apt-get install python-pip
    pip install molecule molecule-docker
    ```

1. Init role

    ```bash
    molecule init role --driver-name docker basic-https-server
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

1. Run dry-run

    ```bash
    molecule test
    ```

## Implementation

Now I want to create real-world role so I decided to use this [repo][1],
as a skeleton. I add change only a few file.

1. Better caching

    ```bash
    # templates/httpd.conf.j2
    # add Apache’s Mod_Expires
    LoadModule expires_module modules/mod_expires.so

    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType text/css "access 2 months"
        ExpiresByType text/html "modification 4 hours"
        ExpiresDefault "access 2 days"
    </IfModule>
    ```

1. Deploy content

    ```yaml
    # tasks/main.yaml
    # I assume that we have some artifacts repository
    - name: Download HTML file
      get_url:
        # url: "http://artifactory/project/{{ html_file_version }}/index.html"
        url: https://github.com/htmlpreview/htmlpreview.github.com/blob/master/index.html
        dest: /var/www/html/index.html
        owner: root
        group: root
        mode: '0644'
        force: yes
      notify: restart httpd
      tags:
        - httpd
        - deploy

    - name: Download CSS file
      get_url:
        # url: "http://artifactory/project/{{ html_file_version }}/file.css"
        url: https://github.com/htmlpreview/htmlpreview.github.com/blob/master/index.html
        dest: /var/www/html/file.css
        owner: root
        group: root
        mode: '0644'
        force: yes
      notify: restart httpd
      tags:
        - httpd
        - deploy
    ```

1. And some basis tests

    ```yaml
    # molecule/default/verify.yml
    - name: Check OS family
        assert: { that: "ansible_os_family == 'RedHat'" }

    - stat:
        path: /etc/httpd/conf/httpd.conf
        register: httpd

    - stat:
        path: /etc/httpd/conf.d/ssl.conf
        register: ssl

    - assert:
        that:
          - httpd.stat.exists
          - ssl.stat.exists

    - name: populate service facts
        service_facts:

    - assert:
        that: ansible_facts.services['httpd.service'].state == 'running'
    ```

## First problem

After fast implementation I tried to test my playbook with Molecule.
Unfortunately dockers Centos version has problem with `systemd` support.
After many Googles pages/and tries I decided that, testing on workaround
or preparing playbooks for dockers without thinking about real environment
have no sense. \
What next ? Vagrant support

## Vagrant

1. Installation

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

1. Molecule for vagrant

    ```bash
    pip install molecule python-vagrant molecule-vagrant
    ```

1. Create role

    ```bash
    molecule init role --driver-name vagrat basic-https-server
    ```

1. Copy file into new role

1. And run..

    ```bash
    molecule test
    ```

## Second problem

Now I have work with Vagrant. I want to use `bento/centos-7.7` box,
I declared it into `molecule.yml`, as same as network, CPU, memory etc.
After typing `vagran init` and `vagrant up` I should have prepared box
on my host. But after `molecule test` I get timeouts error, and I can't
find solution. Vagrant support it's experimental, there are lacks in
documentation. So after spending some time I decided to leave this solution
and whole Molecule.

## Here comes Terraform and Bash

Terraform is awesome. But Bash... Bash is live :)

## Terraform implementation

1. Create `.gitignore`.

    ```bash
    cat << EOF > .gitignore
    auth.json
    .terraform/
    terraform.*
    EOF
    ```

1. `Main.tf` file

    ```bash

    locals {
        region_eu = "europe-west3-a"
        p_name = "my-small-gcp-project"
    }


    provider "google" {
        credentials = file("auth.json")
        project     = local.p_name
        region      = local.region_eu
    }

    // A single Google Cloud Engine instance
    resource "google_compute_instance" "ansible-test-machine" {
        count = 1
        name         = "ansible-test-machine"
        machine_type = "e2-medium"
        zone         = local.region_eu

        boot_disk {
            initialize_params {
                image = "centos-7"
            }
        }
        metadata = {
        ssh-keys = "kuba:${file("~/.ssh/id_rsa.pub")}"
    }

    // Make sure flask is installed on all new instances for later steps
    metadata_startup_script = "sudo apt-get update; sudo apt-get upgrade -y; "

    network_interface {
        network = "default"
            access_config {
                // Include this section to give the VM an external ip address
            }
        }
    }
    ```

1. Init Terraform

    ```bash
    terraform init
    ```

1. Run terraform and create workstation

    ```bash
    terraform apply
    ```

1. Use GCP dynamic inventory

    ```bash
    # /etc/ansible/ansible.cfg
    [inventory]
    enable_plugins = gcp_compute

    pip install requests google-auth

1. Implement `*.gcp.yaml`

    ```bash
    # inventory.gcp.yaml
    plugin: gcp_compute
    projects:
    - my-small-gcp-project
    hostnames:
    - name
    auth_kind: serviceaccount
    service_account_file: ./auth.json
    ```

1. Take a try

    ```bash
    $ ansible-inventory --graph -i inventory.gcp.yaml
    @all:
    |--@ungrouped:
    |  |--ansible-test-machine
    ```

1. Move tests to `tests/test.yaml`

1. Delete `molecule` directory

    ```bash
    rm -rf molecule
    ```

1. Put all step into Bash script

    ```bash
    #test-playbook.sh
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
    ```

1. Test it

    ```bash
    chmod +x test-playbook.sh
    bash test-playbook.sh
    ```

1. All green - finally

## Summary

Melecule is hard. It should works, but have some problem like systemd support.
I can't imagine how to test playbook without `systemd support`. It's not molecule
problem, but Dockers itself and isolation approche,
however in my case
Molecule as a testing solution is useless.
Maybe if you have some diffrent kind af project,
like file manipulation etc, then it could be really cool. \
Vagrant support is in alpha phase, so I have problem even with init run. \
But solution based on Terraform and Bash it's really nice.
It's fast, even with comapre to molecule.
It's real world VM inside regular network, without `it's working on my machine` problem.
I'm very happy with final result.
I need to perform some work with playbook and test for sure.
But it's Sunday, so I want to spend some time with my wife :)

[1]: https://github.com/bertvv/ansible-role-httpd