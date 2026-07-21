# watchy

A **Bedrock AgentCore Runtime** agent with two tools:

- `get_capital(country)` - looks up a country's capital city (static table in [agent/agent.py](agent/agent.py))
- `send_email(subject, message)` - sends an email notification via the SNS topic created by [../agent-infra](../agent-infra)

## Deploy order matters

This depends on **agent-infra** (for the SNS topic) and **base-infra** (for the VPC).
Deploy in this order:

1. `base-infra` - the VPC (only needed once)
2. `agent-infra` - the SNS topic + email subscription
3. `watchy` (this folder) - the agent itself

`watchy`'s Terraform reads `agent-infra`'s state directly via `terraform_remote_state`
([main.tf](main.tf)), so step 2 must exist in S3 before step 3 can plan/apply.

## The only parameter you need to supply: `vpc_id`

Everything else has a sensible default. Given a `vpc_id`, this config finds that
VPC's private subnet automatically - it looks for a subnet tagged `Tier=private`,
the same tag `base-infra` sets. If you point `vpc_id` at some other VPC, tag a
subnet the same way first.

## Deploy

Actions tab → **myacc-agentcore-watchy-agent** → Run workflow:

- `TF_STAGE`: `build` (fmt/validate/plan), `deploy` (build+push image, apply), or `destroy`
- `vpc_id`: required
- `aws_region`: optional, defaults to `eu-west-1`

## Invoke

```bash
./invoke.sh "What is the capital of Japan?"
./invoke.sh "Send an email saying the deployment succeeded"

# or
python invoke.py "What is the capital of Japan?"
```

Both scripts auto-resolve the runtime ARN (from local Terraform state, or by
name lookup) - see [../watchy/invoke.sh](invoke.sh) for all the flags.

## Notes

- The email only actually arrives once the address in `agent-infra` has
  **confirmed the SNS subscription** (AWS emails a confirmation link on apply -
  see [../agent-infra/README.md](../agent-infra/README.md)).
- Resource names in this folder are prefixed `myacc-watchy` / `myacc_watchy_agent`
  (not just `watchy`) to avoid colliding with the similarly-named agent in the
  separate `agentcore` GitHub repo, which deploys into the same AWS account.
