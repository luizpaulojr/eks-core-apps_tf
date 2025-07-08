## Instalar pelas instrucoes em: https://docs.aws.amazon.com/eks/latest/userguide/cost-monitoring.html
resource "helm_release" "kubecost" {
  count            = var.kubecost_enable ? 1 : 0
  name             = "kubecost"
  repository       = "https://kubecost.github.io/cost-analyzer"
  version          = var.kubecost_version
  chart            = "cost-analyzer"
  namespace        = "kubecost"
  timeout          = 600
  create_namespace = true
  values = [
    templatefile("./module/helm-values/values-kubecost.yaml", {
      kubecost_url           = "${var.kubecost_url}"
      kubecost_ingress_class = "${var.kubecost_ingress_class}"
    })
  ]
}



