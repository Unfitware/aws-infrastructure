# GitHub Setup Instructions

This document explains how to set up this repository for AWS infrastructure automation using GitHub Actions and Terraform.

## What You Need Before You Start

- An AWS account
- Admin access to the AWS account
- A GitHub account with owner access to this repository
- The GitHub CLI tool (gh) installed on your computer
- AWS CLI installed on your computer
- Bash shell access

## Part 1: Prepare Your AWS Information

You must have this information before you start:

1. Your AWS account ID (12 digits, for example: `123456789012`)
2. Your AWS region (for example: `us-west-2`)
3. A project name (for example: `myproject` or `nbncorp`)
4. AWS SSO profile name (the name of your AWS login profile)

## Part 2: Set Up GitHub Variables (Using GitHub Web UI)

Follow these steps to add variables to your GitHub repository.

### Step 1: Go to Repository Settings

1. Open your repository on GitHub in a web browser
2. Click **Settings** at the top of the page
3. Click **Secrets and variables** in the left menu
4. Click **Variables** to view the variables page

### Step 2: Add the PROJECT_NAME Variable

1. Click **New repository variable**
2. In the **Name** field, type: `PROJECT_NAME`
3. In the **Value** field, type your project name (for example: `nbncorp`)
4. Click **Add variable**

### Step 3: Add the AWS_ACCOUNT_ID Variable

1. Click **New repository variable**
2. In the **Name** field, type: `AWS_ACCOUNT_ID`
3. In the **Value** field, type your AWS account ID (for example: `123456789012`)
4. Click **Add variable**

### Step 4: Add the AWS_REGION Variable

1. Click **New repository variable**
2. In the **Name** field, type: `AWS_REGION`
3. In the **Value** field, type your AWS region (for example: `us-west-2`)
4. Click **Add variable**

### Step 5: Add the OIDC_ROLE_ARN Variable

1. Click **New repository variable**
2. In the **Name** field, type: `OIDC_ROLE_ARN`
3. In the **Value** field, type the full ARN (for example: `arn:aws:iam::123456789012:role/GitHubActions`)
4. Click **Add variable**

## Part 3: Set Up GitHub Variables (Using GH CLI)

Use the GitHub CLI to add variables quickly. Run these commands in your terminal:

```bash
# Replace values in brackets with your actual values
gh variable set PROJECT_NAME --body "nbncorp"
gh variable set AWS_ACCOUNT_ID --body "123456789012"
gh variable set AWS_REGION --body "us-west-2"
gh variable set OIDC_ROLE_ARN --body "arn:aws:iam::123456789012:role/GitHubActions"
```

To verify the variables were added, run:

```bash
gh variable list
```

## Part 4: Create the Production Environment (Using GitHub Web UI)

The production environment protects the apply action with approval steps.

### Step 1: Go to Environments

1. Open your repository on GitHub in a web browser
2. Click **Settings** at the top of the page
3. Click **Environments** in the left menu

### Step 2: Create the Production Environment

1. Click **New environment**
2. In the **Name** field, type: `production`
3. Click **Configure environment**

### Step 3: Add Required Reviewers

1. Turn on **Required reviewers**
2. Click **Add reviewers**
3. Type the GitHub user names or team names who must approve deployments
4. Click **Save protection rules**

## Part 5: Create the Production Environment (Using GH CLI)

Run this command to create the production environment:

```bash
# Create the environment
gh api repos/OWNER/REPO/environments \
  -X POST \
  -f name="production" \
  -f protection_rules[]='{"type": "required_status_checks"}'
```

Replace `OWNER` with your GitHub username and `REPO` with the repository name.

To add required reviewers:

```bash
# Get the environment ID first
gh api repos/OWNER/REPO/environments/production

# Add required reviewers (replace USERNAME with actual GitHub usernames)
gh api repos/OWNER/REPO/environments/production \
  -X PUT \
  -f 'reviewers[][type]=User' \
  -f 'reviewers[][id]=USERNAME'
```

## Part 6: Bootstrap AWS OIDC Trust (Run Locally)

OIDC allows GitHub Actions to authenticate to AWS without stored credentials. You must set this up once in your AWS account.

### Step 1: Configure Your AWS SSO Profile

First, check if you have an AWS SSO profile configured. Run:

```bash
cat ~/.aws/config
```

Look for a section that starts with `[profile your-profile-name]`. You should see entries like:

```
[profile my-admin]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = Admin
region = us-west-2
```

If your profile does not exist, create it. Open `~/.aws/config` in a text editor and add:

```
[profile your-profile-name]
sso_start_url = https://YOUR_ORG.awsapps.com/start
sso_region = us-east-1
sso_account_id = YOUR_ACCOUNT_ID
sso_role_name = Admin
region = us-west-2
```

Replace:
- `YOUR_ORG` with your organization name
- `YOUR_ACCOUNT_ID` with your AWS account ID
- `Admin` with your SSO role name (ask your AWS administrator if unsure)

### Step 2: Log In to AWS

Run this command:

```bash
aws sso login --profile your-profile-name
```

Replace `your-profile-name` with the profile name from your config file.

A web browser will open automatically. Log in with your AWS SSO credentials. When login succeeds, your terminal will show:

```
Successfully logged in via SSO.
```

If the browser does not open, check the terminal output for a URL and open it manually.

### Step 3: Verify Your Login

Confirm that your login works:

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

If you see an error, try logging in again:

```bash
aws sso login --profile your-profile-name
```

Repeat the login process until you see the success output.

### Step 4: Run the Bootstrap Script

Go to the repository folder and run the bootstrap script:

```bash
cd /path/to/aws-infrastructure
AWS_PROFILE=your-profile-name ./terraform/bootstrap/bootstrap-oidc.sh
```

The script is safe to run multiple times. It will update existing resources if they already exist.

### Step 3: Read the Output

The script prints the role ARN at the end. Example:

```
Role ARN: arn:aws:iam::123456789012:role/GitHubActions
```

Copy this ARN. You need it for the `OIDC_ROLE_ARN` variable.

## Part 7: Verify the Setup

### Check GitHub Variables

Run this command to see all variables:

```bash
gh variable list
```

You should see:
- PROJECT_NAME
- AWS_ACCOUNT_ID
- AWS_REGION
- OIDC_ROLE_ARN

### Check GitHub Environments

Run this command:

```bash
gh api repos/OWNER/REPO/environments
```

You should see the `production` environment in the list.

### Check AWS OIDC Provider

Run this command to see if the OIDC provider was created:

```bash
aws iam list-open-id-connect-providers --profile your-profile-name
```

You should see `token.actions.githubusercontent.com` in the list.

### Check AWS Role

Run this command to see if the role was created:

```bash
aws iam get-role --role-name GitHubActions --profile your-profile-name
```

You should see the role details.

## Part 8: Test the Setup

### Run a Manual Terraform Plan

1. Go to your repository on GitHub
2. Click **Actions** at the top of the page
3. Click **Run AWS Login with OIDC and Deploy** in the list on the left
4. Click **Run workflow**
5. Leave **Apply** unchecked
6. Click **Run workflow** again

GitHub Actions will run the Terraform plan and show the results.

### Check the Logs

1. Wait for the workflow to finish
2. Click the workflow run
3. Click the **Terraform plan** job
4. Read the output to check for errors

## Part 9: Update Hardcoded References

The Terraform files use placeholder values. Update these files with your actual values:

1. `terraform/backend.tf` - Change `my-project-tfstate` to your actual S3 bucket name
2. `terraform/variables.tf` - Update the default values with your settings

After you update these files, push them to GitHub:

```bash
git add terraform/backend.tf terraform/variables.tf
git commit -m "Update Terraform configuration with actual values"
git push origin main
```

## Troubleshooting

### Problem: "Invalid start url provided" error during AWS SSO login

**Cause:** The `sso_start_url` in your AWS config file is incorrect or does not exist.

**Solution:** 
1. Open your AWS SSO portal in a web browser
2. Copy the URL from your browser (example: `https://your-org.awsapps.com/start`)
3. Open your AWS config file:
   ```bash
   cat ~/.aws/config
   ```
4. Find your profile section and check the `sso_start_url` line
5. Update it to match your actual SSO portal URL
6. Save the file
7. Try logging in again:
   ```bash
   aws sso login --profile your-profile-name
   ```

If you do not know your SSO start URL, ask your AWS administrator.

### Problem: "Role not found" error in GitHub Actions

**Cause:** The AWS OIDC role was not created.

**Solution:** Run the bootstrap script again:

```bash
AWS_PROFILE=your-profile-name ./terraform/bootstrap/bootstrap-oidc.sh
```

### Problem: "S3 bucket name is invalid" error

**Cause:** The bucket name does not follow AWS naming rules.

**Solution:** S3 bucket names must be:
- Between 3 and 63 characters long
- Only lowercase letters, numbers, hyphens
- Start with a letter or number
- End with a letter or number

Change the bucket name in `terraform/backend.tf` to a valid name.

### Problem: "Access Denied" error in GitHub Actions

**Cause:** The OIDC role does not have correct permissions.

**Solution:** Check the role policy:

```bash
aws iam get-role-policy --role-name GitHubActions --policy-name GitHubActions-TerraformAdmin --profile your-profile-name
```

The policy should allow the required AWS services. Run the bootstrap script again to update permissions.

## Next Steps

After setup is complete:

1. Customize the Terraform configuration for your infrastructure needs
2. Create a new branch for changes
3. Push to GitHub
4. Create a pull request
5. GitHub Actions will run a Terraform plan automatically
6. Review the plan in the pull request
7. Merge the pull request
8. Go to Actions and run the workflow with apply enabled
9. Approve the deployment when prompted

## More Information

- Terraform documentation: https://www.terraform.io/docs
- GitHub Actions documentation: https://docs.github.com/actions
- AWS IAM OIDC provider: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for_idp_oidc.html
