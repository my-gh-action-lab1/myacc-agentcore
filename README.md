# myacc-agentcore

## Layout

| Path | Purpose | Applied by |
|------|---------|------------|
| `bootstrap-oidc/` | GitHub OIDC provider + IAM role the workflow assumes | You, once, locally |
| `base-infra/` | VPC (`10.10.0.0/16`, 2 AZs, 1 public + 1 private subnet, 1 IGW, 1 NAT Gateway) | GitHub Actions (`base-infra-vpc.yml`) |

These are two **separate Terraform states** (own `backend.tf` each) on purpose:
a `terraform destroy` of the VPC must never be able to delete the IAM role/OIDC
provider the workflow is authenticating with, and the OIDC provider is a
one-per-AWS-account singleton that may end up shared by other repos later.

## One-time bootstrap (do this before the first workflow run)

The workflow authenticates to AWS via OIDC role assumption — there are no
long-lived AWS keys in GitHub. That role has to exist *before* the workflow
can run, so it can't be created by the workflow itself. Apply it once, locally,
with your own AWS credentials:

```bash
cd bootstrap-oidc
terraform init
terraform apply
```

If your AWS account **already has** a GitHub OIDC provider (`token.actions.githubusercontent.com`)
from another repo/workflow, set `-var="create_github_oidc_provider=false"` so
this just looks it up instead of failing on a duplicate.

Then take the `github_actions_role_arn` output and add it as a repo secret:

```bash
gh secret set AWS_OIDC_ROLE_ARN --repo my-gh-action-lab1/myacc-agentcore \
  --body "$(terraform output -raw github_actions_role_arn)"
```

## Deploying the VPC

Actions tab → **myacc-agentcore-base-infra-vpc** → Run workflow:

- `TF_STAGE`: `build` (fmt/validate/plan), `deploy` (apply), or `destroy`
- `aws_region`, `vpc_cidr`, `project`: optional overrides (default to the values above)

The workflow runs on a standard GitHub-hosted runner (`ubuntu-latest`).
