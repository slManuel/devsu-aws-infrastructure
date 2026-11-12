locals {
  github_oidc_url  = "https://token.actions.githubusercontent.com"
  api_main_subject = "repo:${var.github_owner}@${var.github_owner_id}/${var.api_repository_name}@${var.api_repository_id}:ref:refs/heads/main"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = local.github_oidc_url
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

data "aws_iam_policy_document" "api_publisher_trust" {
  statement {
    sid     = "TrustOnlyApiMainWorkflow"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.api_main_subject]
    }
  }
}

resource "aws_iam_role" "api_publisher" {
  name                 = "${var.project_name}-api-publisher"
  description          = "Permite al workflow de main publicar la imagen y desplegar la API en el clúster EKS asignado."
  assume_role_policy   = data.aws_iam_policy_document.api_publisher_trust.json
  max_session_duration = 3600
  tags                 = var.tags
}

data "aws_iam_policy_document" "api_publisher" {
  statement {
    sid       = "GetEcrLoginToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushOnlyApiImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.api_ecr_repository_arn]
  }

  statement {
    sid    = "ManageApiClusterRunnerAccess"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:DescribeUpdate",
      "eks:UpdateClusterConfig",
    ]
    resources = [var.api_eks_cluster_arn]
  }
}

resource "aws_iam_role_policy" "api_publisher" {
  name   = "${var.project_name}-api-deploy"
  role   = aws_iam_role.api_publisher.id
  policy = data.aws_iam_policy_document.api_publisher.json
}
