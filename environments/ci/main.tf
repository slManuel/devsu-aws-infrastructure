data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  api_ecr_repository_name = "${var.project_name}-${var.environment}-api"
  api_ecr_repository_arn  = "arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.api_ecr_repository_name}"
  api_ecr_repository_url  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.api_ecr_repository_name}"
  api_eks_cluster_arn     = "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-${var.environment}-cluster"

  ci_tags = {
    Aplicacion = "devsu-python-api"
    Entorno    = "ci"
  }
}

module "github_actions" {
  source = "../../modules/github_actions"

  aws_region             = var.aws_region
  project_name           = "${var.project_name}-${var.environment}"
  github_owner           = var.github_owner
  github_owner_id        = var.github_owner_id
  api_repository_name    = var.api_repository_name
  api_repository_id      = var.api_repository_id
  infra_repository_name  = var.infra_repository_name
  infra_repository_id    = var.infra_repository_id
  api_ecr_repository_arn = local.api_ecr_repository_arn
  api_eks_cluster_arn    = local.api_eks_cluster_arn
  tf_state_bucket_name   = var.tf_state_bucket_name
  tags                   = local.ci_tags
}
