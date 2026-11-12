locals {
  github_oidc_url    = "https://token.actions.githubusercontent.com"
  api_main_subject   = "repo:${var.github_owner}@${var.github_owner_id}/${var.api_repository_name}@${var.api_repository_id}:ref:refs/heads/main"
  infra_main_subject = "repo:${var.github_owner}@${var.github_owner_id}/${var.infra_repository_name}@${var.infra_repository_id}:ref:refs/heads/main"
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

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
  name   = "${var.project_name}-api-ecr-push"
  role   = aws_iam_role.api_publisher.id
  policy = data.aws_iam_policy_document.api_publisher.json
}

data "aws_iam_policy_document" "infrastructure_deployer_trust" {
  statement {
    sid     = "TrustOnlyInfrastructureMain"
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
      values   = [local.infra_main_subject]
    }
  }
}

resource "aws_iam_role" "infrastructure_deployer" {
  name                 = "${var.project_name}-infrastructure-deployer"
  description          = "Permite a GitHub Actions validar y administrar la infraestructura Devsu con Terraform."
  assume_role_policy   = data.aws_iam_policy_document.infrastructure_deployer_trust.json
  max_session_duration = 3600
  tags                 = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "infrastructure_deployer_power_user" {
  role       = aws_iam_role.infrastructure_deployer.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "infrastructure_deployer" {
  statement {
    sid    = "DenyResourcesOutsideProjectRegion"
    effect = "Deny"
    not_actions = [
      "iam:*",
      "sts:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid     = "DenyAccessOutsideTerraformStateBucket"
    effect  = "Deny"
    actions = ["s3:*"]
    not_resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket_name}",
      "arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket_name}/*",
    ]
  }

  statement {
    sid       = "ProtectTerraformStateBucket"
    effect    = "Deny"
    actions   = ["s3:DeleteBucket"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket_name}"]
  }

  statement {
    sid    = "ProtectTerraformStateObjects"
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket_name}/devsu/bootstrap/state/terraform.tfstate",
      "arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket_name}/devsu/ci/terraform.tfstate",
      "arn:${data.aws_partition.current.partition}:s3:::${var.tf_state_bucket_name}/devsu/dev/terraform.tfstate",
    ]
  }

  statement {
    sid       = "DoNotReadApplicationDatabaseCredentials"
    effect    = "Deny"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:BatchGetSecretValue"]
    resources = ["*"]
  }

  statement {
    sid    = "ManageProjectIamRoles"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRoleDescription",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]
  }

  statement {
    sid       = "PassProjectRolesOnlyToAwsWorkloads"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["eks.amazonaws.com", "ec2.amazonaws.com", "pods.eks.amazonaws.com"]
    }
  }

  statement {
    sid    = "ReadProjectIamRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]
  }

  statement {
    sid    = "InspectPowerUserManagedPolicy"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess"]
  }

  statement {
    sid    = "MaintainGitHubOidcProvider"
    effect = "Allow"
    actions = [
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
    ]
    resources = [aws_iam_openid_connect_provider.github.arn]
  }
}

resource "aws_iam_role_policy" "infrastructure_deployer" {
  name   = "${var.project_name}-infrastructure-deployer"
  role   = aws_iam_role.infrastructure_deployer.id
  policy = data.aws_iam_policy_document.infrastructure_deployer.json
}
