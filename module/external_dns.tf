resource "helm_release" "external_dns" {
  count            = var.external_dns_enable ? 1 : 0
  name             = "external-dns"
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  version          = var.external_dns_version
  chart            = "external-dns"
  namespace        = "kube-system"
  values = [
    templatefile("./module/helm-values/values_external_dns.yaml", {
      external_dns_hosted_zone_id = "${var.external_dns_hosted_zone_id}"
      external_dns_hosted_zone_domain = "${var.external_dns_hosted_zone_domain}"
    })
  ]
}


resource "kubernetes_service_account_v1" "external_dns" {
  count = var.external_dns_enable ? 1 : 0

  metadata {
    name      = "external-dns-terraform"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "external-dns-terraform"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${local.account_id}:role/${aws_iam_role.external_dns[count.index].name}"
    }
  }
}

resource "aws_iam_role" "external_dns" {
  count = var.external_dns_enable ? 1 : 0
  name  = "external_dns_Role_terraform"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" : {
            "StringEquals" : {
              "${local.oidc}:aud" : "sts.amazonaws.com",
              "${local.oidc}:sub" : "system:serviceaccount:kube-system:external-dns-terraform"
            }
          }
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_external_dns" {
  count = var.external_dns_enable ? 1 : 0
  role       = aws_iam_role.external_dns[count.index].name
  policy_arn = aws_iam_policy.external_dns_policy[count.index].arn
}

resource "aws_iam_policy" "external_dns_policy" {
  count       = var.external_dns_enable ? 1 : 0
  name        = "external_dns_Policy_terraform"
  description = "External DNS EKS Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/${var.external_dns_hosted_zone_id}"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = ["*"]
      }
    ]
  })
}

