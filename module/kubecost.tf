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

resource "helm_release" "csi_driver" {
  count            = var.kubecost_enable ? 1 : 0
  name             = "aws-ebs-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  version          = var.csi_driver_version
  chart            = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  values = [
    file("./module/helm-values/values-csi-driver.yaml")
  ]
}


resource "kubernetes_service_account_v1" "csi_driver" {
  count = var.kubecost_enable ? 1 : 0

  metadata {
    name      = "csi-driver-terraform"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "csi-driver-terraform"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${local.account_id}:role/${aws_iam_role.csi_driver[count.index].name}"
    }
  }
}

resource "aws_iam_role" "csi_driver" {
  count = var.kubecost_enable ? 1 : 0
  name  = "EBS_CSI_Driver_Role_terraform"

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
              "${local.oidc}:sub" : "system:serviceaccount:kube-system:csi-driver-terraform"
            }
          }
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_csi_driver" {
  count = var.kubecost_enable ? 1 : 0
  role       = aws_iam_role.csi_driver[count.index].name
  policy_arn = aws_iam_policy.csi_policy[count.index].arn
}

resource "aws_iam_policy" "csi_policy" {
  count = var.kubecost_enable ? 1 : 0
  name        = "EBS_CSI_Driver_Policy_terraform"
  description = "EBS EKS Policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "aws:RequestTag/kubernetes.io/cluster/*" : "owned"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/CSIVolumeName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteVolume"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/kubernetes.io/cluster/*" : "owned"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSnapshot"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/CSIVolumeSnapshotName" : "*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSnapshot"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" : "true"
          }
        }
      }
    ]
    }
  )
}
