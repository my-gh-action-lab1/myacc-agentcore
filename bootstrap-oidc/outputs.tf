output "github_actions_role_arn" {
  description = "ARN of the IAM role the GitHub Actions workflow assumes via OIDC. Store this as the AWS_OIDC_ROLE_ARN secret on the myacc-agentcore repo."
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider used."
  value       = local.github_oidc_provider_arn
}
