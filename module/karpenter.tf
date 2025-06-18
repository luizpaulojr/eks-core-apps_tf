resource "helm_release" "karpenter" {
  count      = var.karpenter_enable ? 1 : 0
  name       = "karpenter"
  chart      = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  version    = var.karpenter_version
  namespace  = "kube-system"

  values = [
    file("${path.module}/helm-values/values-karpenter.yaml")
  ]
  set {
    name  = "serviceAccount.name"
    value = "karpenter-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "arn:aws:iam::${local.account_id}:role/${aws_iam_role.eks_karpenter_role[0].name}"
  } 

  set {
    name  = "settings.clusterName"
    value = local.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = local.cluster_endpoint
  }
  set {
    name  = "settings.interruptionQueue"
    value = local.cluster_name
  }
  set {
    name  = "replicas"
    value = "2"
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }
}

## AWS Role for Karpenter
resource "aws_iam_role" "eks_karpenter_role" {
  count = var.karpenter_enable ? 1 : 0
  name  = "AmazonEKSKarpenterRole_terraform"

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
              "${local.oidc}:sub" : "system:serviceaccount:kube-system:karpenter-sa"
            }
          }
        }
      ]
  })
}

## Attaching required AWS Role for Karpenter
resource "aws_iam_role_policy_attachment" "karpenter_node_worker_node_policy" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni_policy" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr_pull" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

## Attaching custom AWS Role for Karpenter
resource "aws_iam_role_policy_attachment" "attach_karpenter_controller_role_policy" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role[count.index].name
  policy_arn = aws_iam_policy.eks_karpenter_policy[count.index].arn
}

## Creating custom role for Karpenter
resource "aws_iam_policy" "eks_karpenter_policy" {
  count       = var.karpenter_enable ? 1 : 0
  name        = "KarpenterControllerPolicy_terraform"
  description = "EKS to Load Balance Policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ssm:GetParameter",
                "ec2:DescribeImages",
                "ec2:RunInstances",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeInstanceTypeOfferings",
                "ec2:DeleteLaunchTemplate",
                "ec2:CreateTags",
                "ec2:CreateLaunchTemplate",
                "ec2:CreateFleet",
                "ec2:DescribeSpotPriceHistory",
                "pricing:GetProducts"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "Karpenter"
        },
        {
            "Action": "ec2:TerminateInstances",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/karpenter.sh/nodepool": "*"
                }
            },
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "ConditionalEC2Termination"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::${local.account_id}:role/AmazonEKSKarpenterRole_terraform",
            "Sid": "PassNodeIAMRole"
        },
        {
            "Effect": "Allow",
            "Action": "eks:DescribeCluster",
            "Resource": "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.cluster_name}",
            "Sid": "EKSClusterEndpointLookup"
        },
        {
            "Sid": "AllowScopedInstanceProfileCreationActions",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
            "iam:CreateInstanceProfile"
            ],
            "Condition": {
            "StringEquals": {
                "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}": "owned",
                "aws:RequestTag/topology.kubernetes.io/region": "${local.region}"
            },
            "StringLike": {
                "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
            }
            }
        },
        {
            "Sid": "AllowScopedInstanceProfileTagActions",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
            "iam:TagInstanceProfile"
            ],
            "Condition": {
            "StringEquals": {
                "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}": "owned",
                "aws:ResourceTag/topology.kubernetes.io/region": "${local.region}",
                "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}": "owned",
                "aws:RequestTag/topology.kubernetes.io/region": "${local.region}"
            },
            "StringLike": {
                "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*",
                "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
            }
            }
        },
        {
            "Sid": "AllowScopedInstanceProfileActions",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
            "iam:AddRoleToInstanceProfile",
            "iam:RemoveRoleFromInstanceProfile",
            "iam:DeleteInstanceProfile"
            ],
            "Condition": {
            "StringEquals": {
                "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}": "owned",
                "aws:ResourceTag/topology.kubernetes.io/region": "${local.region}"
            },
            "StringLike": {
                "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*"
            }
            }
        },
        {
            "Sid": "AllowInstanceProfileReadActions",
            "Effect": "Allow",
            "Resource": "*",
            "Action": "iam:GetInstanceProfile"
        }
    ],
    }
  )
}
