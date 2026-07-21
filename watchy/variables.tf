variable "aws_region" {
  description = "AWS region to deploy the watchy agent runtime into."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Name prefix for resource names/tags. Kept distinct from the other repo's watchy agent so names don't collide in the same AWS account."
  type        = string
  default     = "myacc-watchy"
}

variable "agent_runtime_name" {
  description = "AgentCore runtime name (letters, digits, underscores only)."
  type        = string
  default     = "myacc_watchy_agent"
}

# The single user-supplied parameter this deployment needs.
variable "vpc_id" {
  description = "VPC to place the AgentCore runtime in. Its private subnet(s) are auto-discovered by the 'Tier=private' tag that base-infra sets."
  type        = string
}

variable "model_id" {
  description = "Bedrock model (or cross-region inference profile) id the agent reasons with."
  type        = string
  default     = "eu.anthropic.claude-sonnet-5"
}

variable "ecr_repo_name" {
  description = "ECR repository name for the agent image."
  type        = string
  default     = "myacc-watchy-agent"
}

variable "image_tag" {
  description = "Image tag deployed to the runtime (the workflow overrides this with the git SHA)."
  type        = string
  default     = "latest"
}
