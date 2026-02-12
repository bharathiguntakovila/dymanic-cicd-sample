# 🚀 GitHub Repository Setup & Deployment Guide

Complete step-by-step instructions for configuring your GitHub repository with Power Platform CI/CD automation.

## 📋 Prerequisites

Before starting, you need:

- ✅ GitHub repository created (public or private)
- ✅ Power Platform tenant access with admin privileges
- ✅ Service Principal configured with Dataverse API permissions
- ✅ Solution unpacked in `/src/` directory
- ✅ Slack workspace (optional, for notifications)
- ✅ Nexus Repository Manager (optional, for artifact storage)

---

## 🔐 Step 1: Create GitHub Secrets

GitHub Secrets store sensitive credentials securely and are masked in workflow logs.

### Navigate to Repository Secrets

1. Go to your repository on GitHub
2. Click **Settings** (top-right)
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Add These 6 Required Secrets

#### 1. `TENANT_ID`
- **Description:** Your Azure AD Tenant ID
- **Value:** UUID from Azure Portal (Settings → Tenant properties)
- **Example:** `12345678-1234-1234-1234-123456789012`

```bash
# Find via Azure Portal or Azure CLI:
az account show --query tenantId -o tsv
```

#### 2. `CLIENT_ID`
- **Description:** Service Principal Application ID
- **Value:** From registered app in Azure AD
- **Example:** `87654321-4321-4321-4321-210987654321`

#### 3. `CLIENT_SECRET`
- **Description:** Service Principal Secret
- **Value:** Generated secret from Azure AD app registration
- **⚠️ WARNING:** Never commit this value, rotate quarterly

```bash
# Generate via Azure Portal
# App registrations → [Your App] → Certificates & secrets → New client secret
```

#### 4. `ENVIRONMENT_URL_DEV`
- **Description:** Development environment URL
- **Value:** `https://yourorg-dev.crm.dynamics.com`
- **Obtain from:** Power Platform Admin Center → Environments

#### 5. `ENVIRONMENT_URL_TEST`
- **Description:** Test environment URL
- **Value:** `https://yourorg-test.crm.dynamics.com`

#### 6. `ENVIRONMENT_URL_PROD`
- **Description:** Production environment URL (or ENVIRONMENT_URL_PREPROD)
- **Value:** `https://yourorg.crm.dynamics.com`

#### (Optional) Additional Secrets

```
ENVIRONMENT_URL_PREPROD = https://yourorg-preprod.crm.dynamics.com
SLACK_WEBHOOK = https://hooks.slack.com/services/T00000000/B00000000/...
SLACK_WEBHOOK_CRITICAL = (for critical alerts)
NEXUS_USERNAME = (for artifact storage)
NEXUS_PASSWORD = (for artifact storage)
```

### Verification

After adding all secrets:
```
✅ TENANT_ID
✅ CLIENT_ID
✅ CLIENT_SECRET
✅ ENVIRONMENT_URL_DEV
✅ ENVIRONMENT_URL_TEST
✅ ENVIRONMENT_URL_PROD
```

---

## 🏗️ Step 2: Create GitHub Environments (for Approval Gates)

Environments enable approval requirements for production deployments.

### Create Environment: `production-security`

1. Go to **Settings** → **Environments**
2. Click **New Environment**
3. Name: `production-security`
4. Configure:
   - ✅ **Enable protection rules**
   - ✅ **Add reviewers**: Security team members (min 1)
   - ⏱️ **Timeout after**: 7 days

### Create Environment: `production-release`

1. Click **New Environment** again
2. Name: `production-release`
3. Configure:
   - ✅ **Enable protection rules**
   - ✅ **Add reviewers**: Release managers (min 1, ideally 2)
   - ⏱️ **Timeout after**: 7 days

### Environment Protection Rules Summary

| Environment | Purpose | Required Approvers | Auto-Approve |
|------------|---------|-------------------|---|
| production-security | Security review gate | Security team (1+) | No |
| production-release | Release approval gate | Release managers (2+) | No |

---

## 🔗 Step 3: Configure Branch Protection Rules

Ensure code quality through automated branch protection.

### Protect Main Branch

1. Go to **Settings** → **Branches**
2. Click **Add rule** under "Branch protection rules"
3. Configure for `main`:

```
✅ Require pull request reviews before merging
   - Required number of reviews: 2
   - Dismiss stale PR approvals: ✓
   - Require review from code owners: ✓
   - Allow specified actors to bypass: (none)

✅ Require status checks to pass before merging
   - Require branches to be up to date: ✓
   - Status checks (select all):
     ✓ PR Validation (1-pr-validation.yml)
     ✓ Code Quality Checks
     ✓ Security Scanning

✅ Require conversation resolution before merging

✅ Include administrators
```

### Protect Develop Branch

1. Click **Add rule** again
2. Configure for `develop`:

```
✅ Require pull request reviews: 1 reviewer
✅ Require status checks to pass
✅ Include administrators
```

### Protect Release Branches

1. Click **Add rule** again
2. Pattern: `release/*`

```
✅ Require pull request reviews: 1 reviewer
✅ Require status checks to pass
```

---

## 🔄 Step 4: Configure Workflow Permissions

Workflows need proper permissions to create releases and manage deployments.

### Enable Workflow Permissions

1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions":

```
✅ Read and write permissions
   - Workflows can read and write to repo
   
✅ Allow GitHub Actions to create and approve pull requests
   - Workflows can create PRs and manage releases
```

---

## 📦 Step 5: Configure Slack Integration (Optional)

Enable real-time notifications for deployments.

### Create Slack Webhook

1. Go to Slack workspace (Workspace Admin)
2. Navigate to **Apps & Integrations** → **Build**
3. Click **Create New App** → **From scratch**
4. Name: `GitHub Actions`
5. Select workspace
6. Go to **Incoming Webhooks**
7. Click **Add New Webhook to Workspace**
8. Select channel: `#deployments` (create if needed)
9. Copy webhook URL: `https://hooks.slack.com/services/...`

### Add Slack Webhooks as Secrets

1. In GitHub: **Settings** → **Secrets** → **New repository secret**
2. Name: `SLACK_WEBHOOK`
3. Paste webhook URL
4. (Optional) Create second webhook for `SLACK_WEBHOOK_CRITICAL` to different channel

---

## ✅ Step 6: Verify Service Principal Permissions

Ensure service principal has required Power Platform permissions.

### Required Permissions

```
✅ User.Read (Azure AD)
✅ Dynamics CRM / Dataverse
   - Solution.Create
   - Solution.Read
   - Solution.Write
   - Solution.Delete
✅ Environment.Create (for new environment provisioning)
✅ Tenant.Read (tenant administration)
```

### Test Authentication

Create test workflow file `.github/workflows/test-auth.yml`:

```yaml
name: Test Authentication

on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Test Service Principal
        uses: microsoft/powerplatform-actions/authenticate@v0
        with:
          environment-url: ${{ secrets.ENVIRONMENT_URL_DEV }}
          tenant-id: ${{ secrets.TENANT_ID }}
          app-id: ${{ secrets.CLIENT_ID }}
          client-secret: ${{ secrets.CLIENT_SECRET }}

      - name: Verify Access
        uses: microsoft/powerplatform-actions/who-am-i@v0
```

Run workflow:
1. Go to **Actions** tab
2. Click **Test Authentication**
3. Click **Run workflow**
4. Wait ~1 minute for completion
5. ✅ Check for green checkmark

---

## 📁 Step 7: Configure Repository Structure

Ensure proper folder structure for workflows.

### Expected Structure

```
.github/
├── workflows/
│   ├── 1-pr-validation.yml
│   ├── 2-deploy-test.yml
│   ├── 3-deploy-production.yml
│   ├── 4-rollback.yml
│   ├── 5-maintenance.yml
│   ├── 6-health-check.yml
│   ├── 7-solution-monitoring.yml
│   ├── 8-provisioning.yml
│   └── pull_request_template.md
├── CODEOWNERS
└── .gitignore

docs/
├── ALM-Architecture-Validation.md
├── Quick-Reference-Guide.md
├── Implementation-Readiness-Checklist.md
├── *.drawio (diagrams)
└── GitHub-Setup-Guide.md (this file)

src/
├── main/
│   ├── Customizations.xml
│   │── Entities/
│   │── Plugins/
│   │── WebResources/
│   └── ... (unpacked solution)
└── ... (other solutions)

build/
└── (generated build artifacts)
```

### Create Directories

```bash
mkdir -p .github/workflows
mkdir -p docs
mkdir -p src/main
mkdir -p build
```

---

## 🧪 Step 8: Initial Test Run

Verify everything works with a test PR.

### Create Test Feature Branch

```bash
git checkout -b feature/crm-001/TEST-001/verify-setup
echo "# Test" >> README.md
git add README.md
git commit -m "test: verify CI/CD setup"
git push origin feature/...
```

### Create Pull Request

1. Go to repository on GitHub
2. Click **Compare & pull request**
3. Fill PR template
4. Create PR

### Watch Workflow Run

1. Go to **Actions** tab
2. Click **🧹 PR Validation** workflow
3. Monitor execution (~5-10 minutes)
4. Check for ✅ all steps pass

### Expected Results

```
✅ Branch naming validation: PASS
✅ Solution Checker: PASS (if solution present)
✅ Code quality checks: PASS
✅ Security scanning: PASS
✅ PR comment created: PASS
```

---

## 🔄 Step 9: Configure Artifact Storage (Optional - Nexus)

If using Nexus for build artifacts:

### Add Nexus Credentials

1. **Settings** → **Secrets** → **New repository secret**
2. `NEXUS_USERNAME`: Your Nexus username
3. `NEXUS_PASSWORD`: Your Nexus password

### Update Workflow

Modify `2-deploy-test.yml` to publish to Nexus:

```yaml
- name: 📤 Publish to Nexus
  uses: actions/upload-artifact@v3
  with:
    name: solution-managed-${{ env.VERSION }}
    path: solution-managed.zip
    retention-days: 90
```

---

## 📊 Step 10: Setup Monitoring & Dashboards

### GitHub Actions Dashboard

1. Go to **Actions** tab in GitHub
2. Pin frequently-used workflows:
   - 1-pr-validation.yml
   - 2-deploy-test.yml
   - 3-deploy-production.yml
   - 4-rollback.yml

### Create GitHub Projects (Optional)

1. Go to **Projects** tab
2. Click **New Project**
3. Name: `CI/CD Pipeline`
4. Add automated automations:
   - Deployment PRs → In Progress
   - Deployments merged → Done

### View Workflow Runs

```
All → Successful → Failed → Canceled → Skipped
```

---

## 🐛 Troubleshooting

### Service Principal Authentication Fails

**Error:** `unauthorized access`

**Solution:**
```bash
# Verify service principal has necessary permissions
# 1. Check Azure AD app registration permissions
# 2. Confirm grant admin consent
# 3. Test with Azure CLI:
az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID
```

### Workflows Not Triggering

**Error:** No workflow runs appear when PRs created

**Solution:**
```
1. Verify branch protection rules configured
2. Confirm workflow files in correct path: .github/workflows/
3. Check branch name matches trigger conditions
4. Review workflow YAML syntax
```

### Secret Not Available in Workflow

**Error:** `Error: Secret not found`

**Solution:**
```
1. Verify secret name matches exactly (case-sensitive)
2. Check secret added to correct repository (not org)
3. Confirm workflow runs on correct runner (ubuntu-latest)
4. Secrets not available in PR from forks (security)
```

### Production Approval Timeout

**Error:** Workflow waiting indefinitely for approval

**Solution:**
```
1. Check environment configuration: Settings → Environments
2. Verify reviewers properly added
3. Contact reviewers if they didn't receive notification
4. Cancel workflow and manually review if needed
```

---

## 📋 Post-Setup Checklist

Before considering setup complete:

- [ ] ✅ All 6 secrets configured
- [ ] ✅ 2 environments created (production-security, production-release)
- [ ] ✅ Branch protection rules configured
- [ ] ✅ Workflow permissions enabled
- [ ] ✅ Slack integration configured (optional)
- [ ] ✅ Service principal authentication tested
- [ ] ✅ All workflows files in `.github/workflows/`
- [ ] ✅ Repository structure matches expected layout
- [ ] ✅ Test PR created and validation passed
- [ ] ✅ Team documentation updated
- [ ] ✅ Rollback plan documented

---

## 🚀 Ready for Production!

Once all above steps complete:

1. **First Feature Development**
   ```bash
   git checkout -b feature/crm-001/US-001/your-feature
   # Make changes...
   git push origin feature/crm-001/US-001/your-feature
   ```

2. **Create Pull Request** → Triggers PR Validation

3. **Merge to develop** → Triggers TEST Deployment

4. **Create release/v1.0.0** → Prepares production deployment

5. **Merge to main** → Requires approvals → Production deployment

6. **In case of rollback**
   - Go to **Actions** → **🔄 Rollback**
   - Click **Run workflow**
   - Select environment and version
   - Workflow handles everything else

---

## 📚 Additional Resources

- [Power Platform ALM Documentation](./ALM-Architecture-Validation.md)
- [Quick Reference Guide](./Quick-Reference-Guide.md)
- [Microsoft Learn ALM](https://learn.microsoft.com/en-us/power-platform/alm/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Microsoft Power Platform GitHub Actions](https://github.com/microsoft/powerplatform-actions)

---

## 💡 Next Steps

1. **Team Training** - Conduct session on Git Flow and PR process
2. **Documentation** - Create team runbooks for common scenarios
3. **Monitoring** - Setup Slack alerts and dashboards
4. **Optimization** - Fine-tune workflow performance based on actual runs
5. **Scaling** - Plan for multi-solution strategy if needed

---

*Last Updated: November 2024*
*For questions or improvements, see CONTRIBUTING.md*
