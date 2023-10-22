# Create Linux Azure AKS Spot instance Node Pool
# Required extension:
#    az extension add --name aks-preview
#
# Get credentials
#    az aks get-credentials -n <cluster_name> -g <resource_group>

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  #checkov:skip=CKV_AZURE_170:Ensure that AKS use the Paid Sku for its SLA
  #checkov:skip=CKV_AZURE_117:Ensure that AKS uses disk encryption set
  #checkov:skip=CKV_AZURE_141:Ensure AKS local admin account is disabled
  #checkov:skip=CKV_AZURE_115:Ensure that AKS enables private clusters
  #checkov:skip=CKV_AZURE_4:Ensure AKS logging to Azure Monitoring is Configured
  name                      = var.cluster_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = var.dns_prefix
  kubernetes_version        = var.kubernetes_version
  node_resource_group       = var.node_resource_group_name
  azure_policy_enabled      = true
  private_cluster_enabled   = true
  automatic_channel_upgrade = "stable"


  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = "Standard_B2ms" # You can adjust the VM size as needed
    enable_auto_scaling = false
    vnet_subnet_id      = data.azurerm_subnet.network_subnet.id
    max_pods            = 50
    # os_disk_type           = "Ephemeral"
    # enable_host_encryption = true
  }

  # api_server_access_profile {
  #   authorized_ip_ranges = ["X.X.X.X/32"]
  # }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }

  linux_profile {
    admin_username = "juliansootca"
    ssh_key {
      key_data = data.azurerm_ssh_public_key.juliansotoca_key.public_key
    }
  }

  tags = {
    environment = "${var.environment}"
    project     = "${var.project}"
  }
}


# SPOT Instances
resource "azurerm_kubernetes_cluster_node_pool" "nodepool_cpu_spot" {
  #checkov:skip=CKV_AZURE_227:Ensure that the AKS cluster encrypt temp disks, caches, and data flows between Compute and Storage resources
  #availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  max_count             = 3
  min_count             = 1
  mode                  = "User"
  name                  = "cpuspot"
  #orchestrator_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  orchestrator_version = azurerm_kubernetes_cluster.aks_cluster.kubernetes_version
  os_disk_size_gb      = 128
  os_type              = "Linux"            # Default is Linux, we can change to Windows
  vm_size              = "standard_d16s_v4" # "Standard_NC6_Promo" Promo is not available for Spot instances
  priority             = "Spot"             # Default is Regular, we can change to Spot with additional settings like eviction_policy, spot_max_price, node_labels and node_taints
  spot_max_price       = -1                 # Set to -1 to disable the max_price (not eviction based on price)
  eviction_policy      = "Delete"           # Deallocate will count against your quota and there is no guarantee the node can be realocated
  vnet_subnet_id       = data.azurerm_subnet.network_subnet.id
  node_taints          = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  max_pods             = 50
  # os_disk_type           = "Ephemeral"
  # enable_host_encryption = true
  node_labels = {
    "nodepool-type"                         = "user"
    "environment"                           = var.environment
    "nodepoolos"                            = "linux"
    "sku"                                   = "cpu"
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  tags = {
    nodepool-type = "user"
    environment   = "${var.environment}"
    project       = "${var.project}"
    nodepoolos    = "linux"
    sku           = "cpu"
  }
}
