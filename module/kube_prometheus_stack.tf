resource "helm_release" "kube_prometheus_stack" {
  count            = var.kube_prometheus_stack_enable ? 1 : 0
  name             = "kube-prometheus-stack"
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = var.kube_prometheus_stack_version
  namespace        = "monitoring"
  create_namespace = true
  values = [
    templatefile("./module/helm-values/values-prometheus-stack.yaml", {
      kube_prometheus_stack_grafana_url = "${var.kube_prometheus_stack_grafana_url}"
      kube_prometheus_stack_grafana_ingress_class = "${var.kube_prometheus_stack_grafana_ingress_class}"
    })
  ]
}
