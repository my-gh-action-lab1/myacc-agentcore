output "sns_topic_arn" {
  description = "ARN of the SNS topic watchy publishes email notifications to."
  value       = aws_sns_topic.notifications.arn
}
