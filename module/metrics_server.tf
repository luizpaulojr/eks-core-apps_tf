resource "helm_release" "metrics_server" {
  count      = var.metrics_server_enable ? 1 : 0
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  version    = var.metrics_server_version
  namespace  = "kube-system"
}