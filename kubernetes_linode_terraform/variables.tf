variable "linode_token" {
  description = "Linode APIv4 Personal Access Token"
}

variable "region" {
  default = "us-central"
}

variable "public_ssh_key" {
  description = "SSH Public Key Fingerprint"
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_ssh_key" {
  description = "SSH Public Key Fingerprint"
  default     = "~/.ssh/id_rsa"
}

resource "random_string" "password" {
  length  = 32
  special = true
}

variable "linode_kubernetes_master_size" {
  description = "size of the VM for the master server"
  default     = "g6-standard-4"
}

variable "linode_kubernetes_node_size" {
  description = "size of the VM for the worker nodes"
  default     = "g6-standard-2"
}
variable "linode_kubernetes_nfs_size" {
  description = "size of the VM for the NFS Server"
  default     = "g6-nanode-1"
}
variable "linode_kubernetes_bastion_size" {
  description = "size of the VM for the bastion host"
  default     = "g6-nanode-1"
}
