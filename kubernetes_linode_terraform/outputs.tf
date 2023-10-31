output "master-publicip" {
  value = linode_instance.master.*.ip_address[0]
}


output "worker-public-ip" {
  value = linode_instance.worker[*].*.ip_address[0]
}


output "nfs-public" {
  value = linode_instance.nfs.*.ip_address[0]
}

