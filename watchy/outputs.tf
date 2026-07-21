output "agent_runtime_arn" {
  description = "ARN of the watchy AgentCore runtime."
  value       = aws_bedrockagentcore_agent_runtime.watchy.agent_runtime_arn
}

output "agent_runtime_id" {
  description = "ID of the watchy AgentCore runtime."
  value       = aws_bedrockagentcore_agent_runtime.watchy.agent_runtime_id
}

output "ecr_repository_url" {
  description = "ECR repository URL for the agent image."
  value       = aws_ecr_repository.watchy_agent.repository_url
}

output "runtime_security_group_id" {
  description = "Security group attached to the runtime ENIs."
  value       = aws_security_group.runtime.id
}
