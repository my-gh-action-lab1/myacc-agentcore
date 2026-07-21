# agent-infra

The "other infra" `watchy` needs beyond the AgentCore Runtime itself: one SNS
topic with an email subscription, so the agent's `send_email` tool has
somewhere to publish to.

Deploy **this before `watchy`** - watchy's Terraform reads the `sns_topic_arn`
output straight out of this folder's state file (`terraform_remote_state`),
so it must exist first.

## Parameter

- `notification_email` (required) - the address that receives notifications.

## Deploy

Actions tab → **myacc-agentcore-agent-infra** → Run workflow:

- `TF_STAGE`: `build` / `deploy` / `destroy`
- `notification_email`: required
- `aws_region`: optional, defaults to `eu-west-1`

## Important: confirm the subscription

Right after `deploy`, AWS sends a **confirmation email** to `notification_email`.
The subscription sits in `PendingConfirmation` - and watchy's emails silently
go nowhere - until someone clicks the link in that email. This confirmation
step can't be automated away; it's AWS's built-in protection against
subscribing an address that isn't yours.
