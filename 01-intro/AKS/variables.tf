variable "resource_group_name" { description = "The name of the resource group" }
variable "node_resource_group_name" { description = "The name of the resource group for K8s resources" }
variable "environment" { description = "The environment (dev, test, prod...)" }
variable "location" {
  description = "The Azure region where all resources in this example should be created"
  default     = "northeurope"
}
variable "cluster_name" { description = "Name of the AKS cluster" }
variable "dns_prefix" { description = "DNS prefix for the AKS cluster" }

variable "project" { description = "resource project name" }
variable "virtual_network" { description = "The name of virtual network used by the VMs" }
variable "subnet" { description = "The name of the subnet belonging to the virtual network" }
variable "kubernetes_version" {
  description = "Version of the kubernetes cluster"
  default     = "1.26.6"
}
