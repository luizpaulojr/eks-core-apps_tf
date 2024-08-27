
resource "helm_release" "ingress_gateway" {
  count            = var.nginx_controler_enable ? 1 : 0
  name             = "ingress"
  chart            = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  version          = var.nginx_controler_version
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    templatefile("./module/helm-values/values-nginx.yaml", {
      SSL_CERT = "${var.certificate_arn}"
    })
  ]
  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}



