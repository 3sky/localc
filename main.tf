
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
 name         = "node"
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


resource "google_compute_firewall" "default" {
 name    = "app-firewall"
 network = "default"

 allow {
   protocol = "tcp"
   ports    = ["80"]
 }
}


