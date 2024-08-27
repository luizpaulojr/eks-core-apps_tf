resource "helm_release" "kube_dashboard" {
  count            = var.kube_dashboard_enable ? 1 : 0
  name             = "kubernetes-dashboard"
  repository       = "https://kubernetes.github.io/dashboard"
  version          = var.kube_dashboard_version
  chart            = "kubernetes-dashboard"
  namespace        = "kubernetes-dashboard"
  create_namespace = true
  values = [
    templatefile("./module/helm-values/values-kube-dashboard.yaml", {})
  ]
}

# Ingress
resource "kubernetes_ingress_v1" "kube_dashboard" {
  count = var.kube_dashboard_enable ? 1 : 0
  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"

    annotations = {
      "meta.helm.sh/release-name"                    = "kubernetes-dashboard"
      "meta.helm.sh/release-namespace"               = "kubernetes-dashboard"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      "service.alpha.kubernetes.io/app-protocols"    = "{\"https\":\"HTTPS\"}"
    }
  }

  spec {
    ingress_class_name = var.kube_dashboard_ingress_class
    rule {
      host = var.kube_dashboard_url
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "kubernetes-dashboard-kong-proxy"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }
}

# Token
resource "kubernetes_service_account" "dashboard_admin" {
  count = var.kube_dashboard_enable ? 1 : 0
  metadata {
    name      = "dashboard-admin"
    namespace = "kubernetes-dashboard"
  }
}

resource "kubernetes_cluster_role" "dashboard_admin" {
  count = var.kube_dashboard_enable ? 1 : 0
  metadata {
    name = "dashboard-admin"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "dashboard_admin" {
  count = var.kube_dashboard_enable ? 1 : 0
  metadata {
    name = "dashboard-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "dashboard-admin"
    namespace = "kubernetes-dashboard"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "dashboard-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_secret" "dashboard_admin" {
  count = var.kube_dashboard_enable ? 1 : 0
  metadata {
    name      = "dashboard-admin"
    namespace = "kubernetes-dashboard"

    annotations = {
      "kubernetes.io/service-account.name" = "dashboard-admin"
    }
  }

  type = "kubernetes.io/service-account-token"
}