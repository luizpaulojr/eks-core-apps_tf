# terraform {
#   backend "s3" {
#     bucket         = "meiosdepagamento-dev-terraform-states-bucket"
#     key            = "infraestrutura/eks-core-apps/terraform.tfstate"
#     region         = "ca-central-1"
#     dynamodb_table = "meios-de-pagamento-dev-terraform-state-lock-table"
#   }
# }
