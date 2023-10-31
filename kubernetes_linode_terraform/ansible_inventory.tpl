# Generated Ansible Inventory
[worker]
%{ for i, ip in nodes_ips ~}
worker-${i + 1} ansible_host=${ip}
%{ endfor ~}

[master]
%{ for i, ip in master_ips ~}
master-${i + 1} ansible_host=${ip}
%{ endfor ~}

[nfs]
%{ for i, ip in nfs_ips ~}
nfs-${i + 1} ansible_host=${ip}
%{ endfor ~}
