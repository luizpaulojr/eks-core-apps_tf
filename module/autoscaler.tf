resource "helm_release" "autoscaler" {
  count      = var.autoscaler_enable ? 1 : 0
  name       = "autoscaler"
  chart      = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  version    = var.autoscaler_version
  namespace  = "kube-system"

  set {
    name  = "awsRegion"
    value = local.region
  }
  set {
    name  = "autoDiscovery.clusterName"
    value = local.cluster_name
  }
  set {
    name  = "replicaCount"
    value = 1
  }
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "resources.requests.memory"
    value = "300Mi"
  }
  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler-terraform"
  }
  depends_on = [
    kubernetes_service_account_v1.aws_cluster_autoscaler_sa
  ]
}

resource "kubernetes_service_account_v1" "aws_cluster_autoscaler_sa" {
  count = var.autoscaler_enable ? 1 : 0
  metadata {
    name      = "cluster-autoscaler-terraform"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "cluster-autoscaler-terraform"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${local.account_id}:role/${aws_iam_role.eks_cluster_autoscaler_role[count.index].name}"
    }
  }
}

# ROLES e POLICY
resource "aws_iam_role" "eks_cluster_autoscaler_role" {
  count = var.autoscaler_enable ? 1 : 0

  name = "AmazonEKSClusterAutoscalerRole_terraform"
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
              "${local.oidc}:sub" : "system:serviceaccount:kube-system:cluster-autoscaler-terraform"
            }
          }
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_cluster_autoscaler_role_policy" {
  count      = var.autoscaler_enable ? 1 : 0
  role       = aws_iam_role.eks_cluster_autoscaler_role[count.index].name
  policy_arn = aws_iam_policy.eks_cluster_autoscaler_policy[count.index].arn
}


resource "aws_iam_policy" "eks_cluster_autoscaler_policy" {
  count       = var.autoscaler_enable ? 1 : 0
  name        = "AmazonEKSClusterAutoscalerPolicy_terraform"
  description = "Policy to work with autoscale"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeImages",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}