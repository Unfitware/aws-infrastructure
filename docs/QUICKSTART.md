# Quick Start Guide

Follow these steps to set up this repository for AWS infrastructure automation.

## Step 1: Prepare Your Information

Before you start, collect this information:

- Your AWS account ID (example: `123456789012`)
- Your AWS region (example: `us-west-2`)
- Your project name (example: `myproject`)
- Your AWS SSO profile name (the name you use to log in to AWS)

## Step 2: Set Up GitHub Variables

You must add four variables to your GitHub repository. These variables tell the workflows where to deploy.

### Method A: Use the GitHub Web UI

1. Go to your repository on GitHub
2. Click **Settings**
3. Click **Secrets and variables** → **Variables**
4. Click **New repository variable**
5. Add these variables one by one:

| Name | Value |
|------|-------|
| `PROJECT_NAME` | Your project name |
| `AWS_ACCOUNT_ID` | Your AWS account ID |
| `AWS_REGION` | Your AWS region |
| `OIDC_ROLE_ARN` | `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions` |

Replace `YOUR_ACCOUNT_ID` with your actual AWS account ID.

### Method B: Use the GH CLI

Run these commands in your terminal:

```bash
gh variable set PROJECT_NAME --body "myproject"
gh variable set AWS_ACCOUNT_ID --body "123456789012"
gh variable set AWS_REGION --body "us-west-2"
gh variable set OIDC_ROLE_ARN --body "arn:aws:iam::123456789012:role/GitHubActions"
```

## Step 3: Bootstrap AWS OIDC Trust

This step creates a trust relationship between GitHub Actions and your AWS account. You run this once on your computer.

### Step 3a: Configure Your AWS SSO Profile

First, check if you have an AWS SSO profile set up. Look in your AWS config file:

```bash
cat ~/.aws/config
```

You should see a section like this:

```
[profile your-profile-name]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = Admin
region = us-west-2
```

If you do not have a profile, ask your AWS administrator for these values and add them to your AWS config file.

### Step 3b: Log In to AWS

Open your terminal and run:

```bash
aws sso login --profile your-profile-name
```

Replace `your-profile-name` with your actual AWS SSO profile name.

A browser window will open. Log in with your AWS SSO credentials. After login, your terminal will show:

```
Successfully logged in via SSO.
```

Confirm your login:

```bash
aws sts get-caller-identity --profile your-profile-name
```

You should see output like this:

```json
{
    "UserId": "XXXXX:username",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/username"
}
```

The `Account` number is your AWS account ID.

### Step 3c: Run the Bootstrap Script

Go to the repository folder and run:

```bash
cd /path/to/aws-infrastructure
AWS_PROFILE=your-profile-name ./terraform/bootstrap/bootstrap-oidc.sh
```

The script will print a message like this:

```
Done.
  Role ARN: arn:aws:iam::123456789012:role/GitHubActions
  Workflows can now assume this role via OIDC — no stored credentials needed.
```

Copy the role ARN and use it for the `OIDC_ROLE_ARN` variable if you have not already set it.

## Step 4: Create the Production Environment

The production environment protects deployments. Only approved users can deploy to production.

### Method A: Use the GitHub Web UI

1. Go to your repository on GitHub
2. Click **Settings**
3. Click **Environments**
4. Click **New environment**
5. Type `production` as the name
6. Click **Configure environment**
7. Turn on **Required reviewers**
8. Add the GitHub usernames of people who can approve deployments
9. Click **Save protection rules**

### Method B: Use the GH CLI

Run this command:

```bash
gh api repos/OWNER/REPO/environments \
  -X POST \
  -f name="production"
```

Replace `OWNER` with your GitHub username and `REPO` with the repository name.

## Step 5: Test the Workflow

Now test that everything works. Run a Terraform plan to make sure the workflow can authenticate to AWS.

### Method A: Use the GitHub Web UI

1. Go to your repository on GitHub
2. Click **Actions**
3. Click **Run AWS Login with OIDC and Deploy**
4. Click **Run workflow**
5. Do NOT check the **Apply** checkbox
6. Click **Run workflow**

Wait for the workflow to finish. It should show green checkmarks.

### Method B: Use the GH CLI

Run this command:

```bash
gh workflow run aws-terraform-plan.yml --ref main
```

Wait a few seconds, then check the status:

```bash
gh run list --workflow aws-terraform-plan.yml --limit 1
```

## Step 6: Update Terraform Configuration

The Terraform files use placeholder bucket names. You must change these to your actual values.

1. Open `terraform/backend.tf`
2. Change `my-project-tfstate` to a unique S3 bucket name
3. Save the file
4. Push to GitHub:

```bash
git add terraform/backend.tf
git commit -m "Update backend bucket name"
git push origin main
```

## Troubleshooting

### Error: "Could not assume role with OIDC"

**Cause:** The OIDC provider or role was not created in AWS.

**Solution:** Run the bootstrap script again:

```bash
AWS_PROFILE=your-profile-name ./terraform/bootstrap/bootstrap-oidc.sh
```

### Error: "Invalid start url provided"

**Cause:** The `sso_start_url` in your AWS config is incorrect.

**Solution:** 
1. Go to your AWS SSO portal in your browser
2. Copy the URL (example: `https://your-org.awsapps.com/start`)
3. Open your AWS config file:
   ```bash
   cat ~/.aws/config
   ```
4. Find your profile and check the `sso_start_url` line
5. Make sure it exactly matches your SSO portal URL
6. Save the file and try logging in again:
   ```bash
   aws sso login --profile your-profile-name
   ```

### Error: "Invalid S3 bucket name"

**Cause:** The bucket name does not follow AWS rules.

**Solution:** S3 bucket names must:
- Be 3 to 63 characters long
- Use only lowercase letters, numbers, hyphens
- Start with a letter or number
- Not end with a hyphen

Change the bucket name in `terraform/backend.tf` to a valid name.

### Error: "Access Denied" in the workflow

**Cause:** The OIDC role does not have the correct permissions.

**Solution:** Run the bootstrap script again to update the permissions:

```bash
AWS_PROFILE=your-profile-name ./terraform/bootstrap/bootstrap-oidc.sh
```

## What's Next

After all steps are complete:

1. Make changes to the Terraform files
2. Push to a new branch
3. Create a pull request
4. The workflow will run a `terraform plan` automatically
5. Review the plan in the pull request
6. Merge the pull request
7. Go to **Actions** and run the workflow with apply enabled
8. A reviewer must approve the deployment

## Learn More

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [AWS IAM OIDC Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for_idp_oidc.html)
