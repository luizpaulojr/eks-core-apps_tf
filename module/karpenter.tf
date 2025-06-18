resource "helm_release" "karpenter" {
  count      = var.karpenter_enable ? 1 : 0
  name       = "karpenter"
  chart      = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  version    = var.karpenter_chart_version
  namespace  = "karpenter"

  create_namespace = true

  values = [
    file("${path.module}/helm-values/karpenter-values.yaml")
  ]

  # Optional: Wait until resources are ready
  timeout = 600
  atomic  = true
}
