variable "aws_region" {
  description = "AWS region to create the notification infra in."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Name prefix for resource names/tags."
  type        = string
  default     = "myacc-watchy"
}

variable "notification_email" {
  description = <<-EOT
    Email address that receives watchy's notifications. AWS emails this
    address a confirmation link right after apply - the subscription stays
    PendingConfirmation, and no emails are delivered, until it's clicked.
  EOT
  type = string
}
