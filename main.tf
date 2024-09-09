module "eks_core_apps" {
  source       = "./module"
  region       = "us-east-1"
  cluster_name = "eks-default"
 
  # kube_proxy - https://docs.aws.amazon.com/pt_br/eks/latest/userguide/managing-kube-proxy.html
  kube_proxy_enable  = true
  kube_proxy_version = "v1.30.0-eksbuild.3"

  # coredns - https://docs.aws.amazon.com/pt_br/eks/latest/userguide/managing-coredns.html
  coredns_enable  = true
  coredns_version = "v1.11.1-eksbuild.9"

  # vpc_cni - https://artifacthub.io/packages/helm/aws/aws-vpc-cni
  vpc_cni_enable      = false
  vpc_cni_version     = "1.18.1"
  subnets_filter_name = "general-subnet"      # subnets da rede CNI
  sg_filter_name      = "eks-default-node" # sg do node

  # aws_load_balancer_controller - https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
  alb_controller_enable  = false
  alb_controller_version = "1.7.2"

  # autoscaler - https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler
  autoscaler_enable  = false
  autoscaler_version = "9.37.0"

  # metrics_server - https://artifacthub.io/packages/helm/metrics-server/metrics-server
  metrics_server_enable  = true
  metrics_server_version = "3.12.1"

  # nginx_controler - https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx
  nginx_controler_enable  = false
  certificate_arn         = "arn:aws:acm:..."
  nginx_controler_version = "4.10.0"

  # kube_dashboard - https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard
  kube_dashboard_enable        = true
  kube_dashboard_version       = "7.1.3"
  kube_dashboard_ingress_class = "nginx"
  kube_dashboard_url           = "kubedashboard.dominio"

  # kubecost - https://artifacthub.io/packages/helm/kubecost/cost-analyzer
  kubecost_enable        = false
  kubecost_version       = "2.3.0"
  csi_driver_version     = "2.31.0"
  kubecost_ingress_class = "nginx"
  kubecost_url           = "kubecost.dominio"
}
