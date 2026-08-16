# aws-infrastructure

Infrastructure-as-code for AWS, built around a **keyless CI pattern**: GitHub
Actions authenticates to AWS via OIDC (no long-lived access keys) and runs
Terraform. The repo also holds the one-time bootstrap that makes that trust
possible.

## Quick Start

For detailed setup instructions, see [docs/SETUP.md](docs/SETUP.md). It covers:
- Setting up GitHub variables and environments
- Running the AWS OIDC bootstrap
- Verifying the setup
- Troubleshooting common issues

## What's here

| Path | Purpose |
|------|---------|
| `terraform/` | The active Terraform root — provisions the S3 state bucket + logging bucket. `TF_WORKING_DIR` in CI. |
| `terraform/bootstrap/bootstrap-oidc.sh` | One-time, run-locally bootstrap of the GitHub Actions OIDC provider + `GitHubActions` IAM role. |
| `terraform/bootstrap/boostrap.sh` | Separate one-time bootstrap of a KMS-encrypted state bucket via AWS CLI. (Filename misspelling is intentional.) |
| `.github/workflows/` | The CI workflows — the heart of the repo. |
| `.github/workflows/bootstrap/terraform-admin-policy.json` | Least-privilege IAM policy attached to the `GitHubActions` role. |
| `snippets/` | Reference snippets (OIDC CloudFormation setup, tagging pipeline). Not part of any deploy. |

## Conventions

- **Region:** `us-west-2`
- **AWS account:** `123456789012` (replace with your account ID)
- **OIDC role:** `arn:aws:iam::123456789012:role/GitHubActions`
- **Terraform:** `>= 1.12.0` (CI pins `1.12.0`); **AWS provider** `~> 5.50`
- **Backend:** S3 (`my-project-tfstate`, key `dev-tfstate`) with native lockfile (`use_lockfile = true`, no DynamoDB)
- **`project_name`** default: `nbncorp` (so the state bucket is `nbncorp-core`, logs `nbncorp-core-logs`)

## One-time setup: bootstrap the OIDC trust

CI can't create its own trust anchor, so this runs **once, locally**, under an
admin identity (e.g. an IAM Identity Center user with `AdministratorAccess`).
It creates the GitHub OIDC provider and the `GitHubActions` role.

```bash
aws sso login --profile <admin-sso-profile>
aws sts get-caller-identity --profile <admin-sso-profile>   # confirm account + identity

# scoped least-privilege policy (default), or PERMISSION_LEVEL=admin for AdministratorAccess
AWS_PROFILE=<admin-sso-profile> ./terraform/bootstrap/bootstrap-oidc.sh
```

The script is idempotent (safe to re-run) and authoritative about the role's
policy — re-running with a different `PERMISSION_LEVEL` swaps `scoped` ⇄ `admin`.
After it succeeds, every workflow below authenticates via OIDC with **no stored
credentials**.

## CI workflows

All workflows authenticate with OIDC:

```yaml
- uses: aws-actions/configure-aws-credentials@v6
  with:
    aws-region: us-west-2
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
    audience: sts.amazonaws.com
```

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `aws-terraform-plan.yml` | `workflow_dispatch` | `plan` job (fmt → init → plan) always runs and uploads the plan artifact. A gated `apply` job applies that exact plan. |
| `aws-inventory.yml` | `workflow_dispatch` | Scans every region (Resource Explorer + Tagging API), builds a CSV/count report, uploads the `aws-inventory` artifact. |

### Running a plan

Actions tab → **Run AWS Login with OIDC and Deploy** → **Run workflow** (leave
`apply` unchecked), or:

```bash
gh workflow run aws-terraform-plan.yml --ref main
```

### Running a gated apply

Apply is protected by **two** independent gates:

1. **Opt-in input** — `apply` must be set to `true` at dispatch:
   ```bash
   gh workflow run aws-terraform-plan.yml --ref main -f apply=true
   ```
2. **Environment approval** — the `apply` job runs in the `production`
   environment, which requires a reviewer to approve in the Actions UI before
   it starts.

On approval, the job downloads the saved plan and runs `terraform apply tfplan`,
so only the reviewed plan is applied. A `concurrency` group prevents two applies
racing the state. State lives in S3 (`s3://my-project-tfstate/dev-tfstate`) — there
is no local `terraform.tfstate`.

## Working with Terraform locally

```bash
cd terraform
terraform fmt -check -recursive
terraform init -input=false      # backend config is hardcoded in backend.tf
terraform plan -input=false
```
