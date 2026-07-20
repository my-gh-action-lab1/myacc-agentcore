variable "aws_region" {
  description = "AWS region to create the IAM/OIDC resources in (IAM is global, but the provider still needs a region)."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Name prefix applied to resource tags."
  type        = string
  default     = "base-infra"
}

variable "create_github_oidc_provider" {
  description = <<-EOT
    Whether to create the IAM OIDC identity provider for token.actions.githubusercontent.com.
    An AWS account can only have ONE OIDC provider per unique URL. Set to false if one already
    exists in this account (from another repo/workflow) and this config will just look it up.
  EOT
  type    = bool
  default = true
}

variable "github_org" {
  description = "GitHub organization allowed to assume the deploy role via OIDC."
  type        = string
  default     = "my-gh-action-lab1"
}

variable "github_repo" {
  description = "GitHub repository (within github_org) allowed to assume the deploy role via OIDC."
  type        = string
  default     = "myacc-agentcore"
}

variable "github_oidc_allowed_refs" {
  description = "Git refs allowed to assume the role, as GitHub OIDC 'sub' claim suffixes."
  type        = list(string)
  default     = ["ref:refs/heads/main"]
}

variable "oidc_role_name" {
  description = "Name of the IAM role the GitHub Actions workflow assumes."
  type        = string
  default     = "myacc-agentcore-gha-oidc-role"
}

variable "state_bucket" {
  description = "S3 bucket holding the base-infra Terraform state (for scoping backend read/write permissions)."
  type        = string
  default     = "dan-terraform-01"
}

variable "state_key_prefix" {
  description = "Key prefix within state_bucket that the deploy role may read/write."
  type        = string
  default     = "myacc-agentcore/base-infra/*"
}
