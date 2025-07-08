# cluster_eks
variable "region" {
  type = string
}
variable "cluster_name" {
  type = string
}

# nginx_controler
variable "nginx_controler_enable" {
  type    = bool
  default = false
}
variable "certificate_arn" {
  type    = string
  default = ""
}
variable "nginx_controler_version" {
  type    = string
  default = null
}

# aws_load_balancer_controller
variable "alb_controller_enable" {
  type    = bool
  default = false
}
variable "alb_controller_version" {
  type    = string
  default = null
}

# autoscaler
variable "autoscaler_enable" {
  type    = bool
  default = false
}
variable "autoscaler_version" {
  type    = string
  default = null
}

# metrics_server
variable "metrics_server_enable" {
  type    = bool
  default = false
}
variable "metrics_server_version" {
  type    = string
  default = null
}

# vpc_cni
variable "vpc_cni_enable" {
  type    = bool
  default = false
}
variable "vpc_cni_version" {
  type    = string
  default = null
}
variable "subnets_filter_name" {
  type    = string
  default = null
}
variable "sg_filter_name" {
  type    = string
  default = null
}

# kube_proxy
variable "kube_proxy_enable" {
  type    = bool
  default = false
}
variable "kube_proxy_version" {
  type    = string
  default = null
}

# coredns
variable "coredns_enable" {
  type    = bool
  default = false
}
variable "coredns_version" {
  type    = string
  default = null
}

# kube_dashboard
variable "kube_dashboard_enable" {
  type    = bool
  default = false
}
variable "kube_dashboard_version" {
  type    = string
  default = null
}
variable "kube_dashboard_url" {
  type    = string
  default = ""
}
variable "kube_dashboard_ingress_class" {
  type    = string
  default = null
}

# kubecost
variable "kubecost_enable" {
  type    = bool
  default = false
}
variable "kubecost_version" {
  type    = string
  default = null
}
variable "kubecost_url" {
  type    = string
  default = ""
}
variable "kubecost_ingress_class" {
  type    = string
  default = null
}

# kube_prometheus_stack
variable "kube_prometheus_stack_enable" {
  type    = bool
  default = false
}
variable "kube_prometheus_stack_version" {
  type    = string
  default = null
}
variable "kube_prometheus_stack_grafana_url" {
  type    = string
  default = ""
}
variable "kube_prometheus_stack_grafana_ingress_class" {
  type    = string
  default = null
}

# aws_ebs_csi_driver 
variable "ebs_csi_driver_enable" {
  type    = bool
  default = false
}
variable "ebs_csi_driver_version" {
  type    = string
  default = null
}

# karpenter
variable "karpenter_enable" {
  type    = string
  default = null
}
variable "karpenter_version" {
  type    = string
  default = null
}

# external_dns 
variable "external_dns_enable" {
  type    = bool
  default = false
}
variable "external_dns_version" {
  type    = string
  default = null
}
variable "external_dns_hosted_zone_id" {
  type    = string
  default = ""
}
variable "external_dns_hosted_zone_domain" {
  type    = string
  default = ""
}

# karpenter node pool config
variable "disk_size" {
  type    = number
  default = null
}
variable "disk_iops" {
  type    = number
  default = null
}
variable "capacity_type" {
  type    = string
  default = null
}
variable "cluster_version" {
  type    = number
  default = null
}
