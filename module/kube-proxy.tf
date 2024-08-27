resource "aws_eks_addon" "kube_proxy" {
  count                       = var.kube_proxy_enable ? 1 : 0
  cluster_name                = local.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  configuration_values = jsonencode({
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
    "eks_addon" = "kube-proxy"
  }
}