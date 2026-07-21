# One SNS topic, with one email subscription. watchy's agent publishes to
# this topic; SNS emails whoever is subscribed.
resource "aws_sns_topic" "notifications" {
  name = "${var.project}-notifications"

  tags = {
    Project = var.project
    Managed = "terraform"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
