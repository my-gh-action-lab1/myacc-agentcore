########################################
# GitHub OIDC provider (account-wide, singleton)
########################################
data "aws_caller_identity" "current" {}

# GitHub's documented OIDC token signing thumbprints (AWS also verifies the
# provider by TLS chain of trust; these values are still a required field).
locals {
  github_oidc_thumbprints = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = local.github_oidc_thumbprints

  tags = {
    Name    = "github-actions-oidc"
    Project = var.project
  }
}

# If an OIDC provider for GitHub already exists in this account (created by
# another repo/workflow), look it up instead of trying to create a duplicate.
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

########################################
# IAM role assumed by the GitHub Actions workflow
########################################
data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # GitHub repos created on/after 2026-07-15 emit the new "immutable subject
    # claims" sub format (repo:OWNER@OWNER-ID/REPO@REPO-ID:ref:...) instead of
    # the classic repo:OWNER/REPO:ref:... . Match both so this works whichever
    # format the target repo actually uses. The @* wildcard for the numeric
    # IDs is safe: GitHub cryptographically signs the token, so nothing can
    # forge a sub claim for a different repo regardless of this wildcard.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = flatten([
        for ref in var.github_oidc_allowed_refs : [
          "repo:${var.github_org}/${var.github_repo}:${ref}",
          "repo:${var.github_org}@*/${var.github_repo}@*:${ref}",
        ]
      ])
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.oidc_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
  tags = {
    Project = var.project
  }
}

########################################
# Permissions: VPC networking + S3 Terraform backend
# (scoped to what base-infra's VPC deployment needs)
########################################
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "VpcNetworking"
    effect = "Allow"
    actions = [
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",
      "ec2:DescribeSubnets",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:DescribeInternetGateways",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:DescribeAddresses",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
      "ec2:DescribeNatGateways",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:ReplaceRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:DescribeRouteTables",
      "ec2:DescribeAvailabilityZones",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "TerraformStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.state_key_prefix]
    }
  }

  statement {
    sid    = "TerraformStateObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["arn:aws:s3:::${var.state_bucket}/${var.state_key_prefix}"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.oidc_role_name}-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
