# eks-core-apps_tf
eks-core-apps_tf

############### Quando utilizar o Karpenter é necessário; ###########
##adicionar tag no subnet e sg do node
karpenter.sh/discovery:eks-cluster
##Adicionar a role no ConfigMap aws-auth ou criar no EKS API access
arn:aws:iam::966255543985:role/AmazonEKSKarpenterRoleNode_terraform
EC2 Linux
system:node:{{EC2PrivateDNSName}}
system:nodes
