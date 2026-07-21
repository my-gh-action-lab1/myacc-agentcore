data "aws_caller_identity" "current" {}

########################################
# Find the private subnet(s) in the given VPC.
# base-infra tags its private subnet Tier=private - if vpc_id points at a
# different VPC, tag a subnet the same way (or edit this data source).
########################################
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

########################################
# Read the SNS topic ARN created by agent-infra (deploy that folder first).
########################################
data "terraform_remote_state" "agent_infra" {
  backend = "s3"
  config = {
    bucket = "dan-terraform-101"
    key    = "myacc-agentcore/agent-infra/terraform.tfstate"
    region = "eu-west-1"
  }
}

locals {
  tags          = { Project = var.project, Managed = "terraform" }
  sns_topic_arn = data.terraform_remote_state.agent_infra.outputs.sns_topic_arn
}

########################################
# ECR repository for the agent image
########################################
resource "aws_ecr_repository" "watchy_agent" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

########################################
# Security group for the runtime's ENIs.
# Egress-only: the agent only ever initiates outbound calls (Bedrock, SNS,
# ECR, CloudWatch Logs) - inbound isn't needed, AgentCore doesn't accept
# direct network connections to the runtime.
########################################
resource "aws_security_group" "runtime" {
  name        = "${var.project}-runtime-sg"
  description = "watchy AgentCore runtime ENIs"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (Bedrock, SNS, ECR, CloudWatch Logs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project}-runtime-sg" })
}

########################################
# IAM role the runtime assumes to call AWS services on the agent's behalf
########################################
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "runtime" {
  name               = "${var.project}-agentcore-runtime-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "runtime" {
  # Pull the agent image from ECR.
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid       = "EcrPull"
    effect    = "Allow"
    actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [aws_ecr_repository.watchy_agent.arn]
  }

  # CloudWatch Logs + observability.
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]
    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"]
  }

  statement {
    sid    = "Telemetry"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
  }

  # AgentCore workload identity tokens.
  statement {
    sid    = "WorkloadIdentity"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:GetWorkloadAccessToken",
      "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
      "bedrock-agentcore:GetWorkloadAccessTokenForUserId",
    ]
    resources = ["*"]
  }

  # Invoke the reasoning model.
  statement {
    sid    = "Bedrock"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = ["*"]
  }

  # Send email notifications through the agent-infra SNS topic.
  statement {
    sid       = "PublishEmail"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [local.sns_topic_arn]
  }
}

resource "aws_iam_role_policy" "runtime" {
  name   = "${var.project}-runtime-policy"
  role   = aws_iam_role.runtime.id
  policy = data.aws_iam_policy_document.runtime.json
}

########################################
# The AgentCore Runtime itself (VPC network mode)
########################################
resource "aws_bedrockagentcore_agent_runtime" "watchy" {
  agent_runtime_name = var.agent_runtime_name
  description        = "watchy - looks up world capitals and can email via SNS"
  role_arn           = aws_iam_role.runtime.arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.watchy_agent.repository_url}:${var.image_tag}"
    }
  }

  network_configuration {
    network_mode = "VPC"

    network_mode_config {
      subnets         = data.aws_subnets.private.ids
      security_groups = [aws_security_group.runtime.id]
    }
  }

  protocol_configuration {
    server_protocol = "HTTP"
  }

  environment_variables = {
    SNS_TOPIC_ARN = local.sns_topic_arn
    MODEL_ID      = var.model_id
  }

  tags = local.tags

  depends_on = [aws_iam_role_policy.runtime]
}
