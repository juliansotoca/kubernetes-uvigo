terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

data "linode_profile" "me" {
}

data "linode_region" "main" {
  id = var.region
}

data "linode_instance_type" "default" {
  id = "g6-nanode-1"
}

data "linode_image" "ubuntu" {
  id = "linode/ubuntu22.04"
}

resource "linode_sshkey" "mykey" {
  ssh_key = chomp(file(var.public_ssh_key))
  label   = "Terraform SSHKey"
}


resource "linode_instance" "master" {
  image = "linode/ubuntu22.04"
  label = "master"

  group            = "master"
  tags             = ["terraform", "kubernetes", "master"]
  region           = var.region
  type             = var.linode_kubernetes_master_size
  authorized_users = [data.linode_profile.me.username]
  private_ip       = true

}

resource "linode_instance" "worker" {
  image = "linode/ubuntu22.04"
  label = "node-${count.index + 1}"
  count = 2

  group            = "workers"
  tags             = ["terraform", "kubernetes", "workers"]
  region           = var.region
  type             = var.linode_kubernetes_node_size
  authorized_users = [data.linode_profile.me.username]
  private_ip       = true
}


resource "linode_instance" "nfs" {
  image = "linode/ubuntu22.04"
  label = "nfs"

  group            = "nfs"
  tags             = ["terraform", "kubernetes", "storage"]
  region           = var.region
  type             = var.linode_kubernetes_node_size
  authorized_users = [data.linode_profile.me.username]
  private_ip       = true
}



resource "linode_firewall" "firewall_cli_nodes" {
  label = "firewall_cli_nodes"

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-all-from-master"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "1-65000"
    ipv4     = ["${linode_instance.master.ip_address}/32"]
    ipv6     = ["::/0"]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  linodes         = concat([for instance in linode_instance.worker : instance.id])
}
resource "linode_firewall" "firewall_cli_master" {
  label = "firewall_cli_master"

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }
  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "6443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }


  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  linodes         = [linode_instance.master.id]
}
resource "linode_firewall" "firewall_cli_nfs" {
  label = "firewall_cli_nfs"

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-all-from-nodes"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "1-65000"
    ipv4     = concat(["${linode_instance.master.ip_address}/32"], [for instance in linode_instance.worker : "${instance.ip_address}/32"])
    ipv6     = ["::/0"]
  }


  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  linodes         = [linode_instance.nfs.id]
}
