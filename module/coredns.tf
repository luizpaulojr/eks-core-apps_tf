resource "aws_eks_addon" "coredns" {
  count                       = var.coredns_enable ? 1 : 0
  cluster_name                = local.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  configuration_values = jsonencode({
    replicaCount = 2
    resources = {
      limits = {
        memory : "170Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "70Mi"
      }
    }
  })
  tags = {
    "eks_addon" = "coredns"
  }
}
