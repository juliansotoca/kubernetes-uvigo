# terraform output -raw kube_config > kubeconfig.yaml

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true
}

output "id" {
  value = azurerm_kubernetes_cluster.aks_cluster.id
}
