data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = "${var.project_name}-${var.environment}"
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )
  common_tags = {
    Aplicacion = "devsu-python-api"
  }
}

data "aws_iam_role" "api_publisher" {
  name = "${var.project_name}-${var.environment}-api-publisher"
}

data "aws_iam_role" "infrastructure_deployer" {
  name = "${var.project_name}-${var.environment}-infrastructure-deployer"
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones
  tags               = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name = "${local.name}-api"
  tags = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  name = "${local.name}/api-runtime"
  tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name                                 = "${local.name}-cluster"
  kubernetes_version                   = var.cluster_version
  subnet_ids                           = module.network.private_app_subnet_ids
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  node_instance_type                   = "t3a.small"
  node_count                           = 2
  api_runtime_secret_arn               = module.secrets.api_runtime_secret_arn
  api_ecr_repository_arn               = module.ecr.repository_arn
  api_deployer_role_arn                = data.aws_iam_role.api_publisher.arn
  infra_deployer_role_arn              = data.aws_iam_role.infrastructure_deployer.arn
  tags                                 = local.common_tags
}

module "database" {
  source = "../../modules/database"

  name                          = "${local.name}-postgres"
  subnet_ids                    = module.network.database_subnet_ids
  vpc_id                        = module.network.vpc_id
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  engine_version                = var.postgres_engine_version
  tags                          = local.common_tags
}
