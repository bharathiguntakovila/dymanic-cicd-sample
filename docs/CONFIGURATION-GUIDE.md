# Workflow Configuration Guide

This comprehensive guide documents all configurable variables and settings across your Power Platform CI/CD workflows. Use this as a reference to understand, customize, and maintain your automation.

---

## Table of Contents

1. [Solution & Project Configuration](#solution--project-configuration)
2. [Environment Configuration](#environment-configuration)
3. [Versioning & Build Configuration](#versioning--build-configuration)
4. [Artifact Management](#artifact-management)
5. [Deployment Configuration](#deployment-configuration)
6. [Branch Configuration](#branch-configuration)
7. [Notification Configuration](#notification-configuration)
8. [Approval Gate Configuration](#approval-gate-configuration)
9. [Monitoring & Health Check Configuration](#monitoring--health-check-configuration)
10. [Security Configuration](#security-configuration)
11. [PR Validation Configuration](#pr-validation-configuration)
12. [Advanced Configuration](#advanced-configuration)
13. [Critical GitHub Setup](#critical-github-setup)
14. [How to Customize](#how-to-customize)

---

## Solution & Project Configuration

### Current Settings

| Setting | Value | Location | Used By |
|---------|-------|----------|---------|
| Solution Name | "Main Solution" | All workflows | Export, Pack, Deploy |
| Managed Solution File | `solution_managed.zip` | Deploy workflows | 2-deploy-test, 3-deploy-production |
| Unmanaged Solution File | `solution.zip` | Export workflows | 1-pr-validation, 2-deploy-test |
| Solution Checker | Enabled | 1-pr-validation | Component validation |
| Severity Level | Medium | 1-pr-validation | Pass/Fail decision |
| Max Canvas Apps | 50 | All workflows | Size validation |
| Max Model Apps | 20 | All workflows | Size validation |
| Max Cloud Flows | 100 | 5-maintenance, 7-solution-monitoring | Governance check |

### How to Customize

**To change solution name:**
- Edit all workflows: Search for `Main Solution` and replace with your solution name
- Also update: Export-Solution step in 1-pr-validation.yml

**To change file names:**
- Update step: "Pack solution to managed" in 2-deploy-test.yml
- Update step: "Pack solution to managed" in 3-deploy-production.yml
- Update unpacking steps in all deploy workflows

**To change component thresholds:**
- Edit: 7-solution-monitoring.yml - "Check solution size" step
- Edit: 1-pr-validation.yml - "Check solution complexity" step

---

## Environment Configuration

### Current Setup (4-Tier Environment)

| Environment | Type | Usage | Branch | Auto-Deploy |
|------------|------|-------|--------|------------|
| **Dev** | Sandbox | Feature development | `feature/*` | No |
| **Test** | Sandbox | QA/Testing | `develop` | Yes |
| **PreProd** | Sandbox (Optional) | Pre-release validation | `release/*` | No |
| **Prod** | Production | Live users | `main` | No (requires approval) |

### Environment URLs (Stored in GitHub Secrets)

```
ENVIRONMENT_URL_DEV    = https://[org]-dev.crm.dynamics.com/
ENVIRONMENT_URL_TEST   = https://[org]-test.crm.dynamics.com/
ENVIRONMENT_URL_PREPROD = https://[org]-preprod.crm.dynamics.com/  (optional)
ENVIRONMENT_URL_PROD   = https://[org]-prod.crm.dynamics.com/
```

### Authentication (Stored in GitHub Secrets)

```
TENANT_ID      = Azure Tenant ID (UUID)
CLIENT_ID      = Service Principal App ID (UUID)
CLIENT_SECRET  = Service Principal Application Secret
```

### How to Add a New Environment

1. **Create the environment in Power Platform admin**
   - Go to Power Platform Admin Center
   - Create new Dataverse environment
   - Note the environment URL

2. **Add GitHub Secret**
   - Settings → Secrets and variables → Actions → New repository secret
   - Name: `ENVIRONMENT_URL_ENVNAME`
   - Value: Full URL with trailing slash

3. **Update Workflows**
   - 2-deploy-test.yml: Add env to health checks
   - 6-health-check.yml: Add env to monitoring list
   - 3-deploy-production.yml: Add backup step for new env (if needed)

---

## Versioning & Build Configuration

### Current Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| Format | Semantic | Major.Minor.Build |
| Version Template | `1.0.{run_number}` | Used in 2-deploy-test.yml |
| Major Version | 1 | Starting version |
| Minor Version | 0 | Starting version |
| Tag Prefix | `v` | Git tag format: `v1.0.123` |

### Version Numbering Strategy

**Semantic Versioning (MAJOR.MINOR.PATCH)**
- **MAJOR** (1st number): Significant breaking changes → Increment manually
- **MINOR** (2nd number): New features, non-breaking → Increment manually  
- **PATCH** (3rd number): Auto-incremented per GitHub Actions run number

**Example Versions:**
- `1.0.1` - First build after initial release
- `1.0.45` - 45th build of version 1.0
- `1.1.1` - New feature release, reset patch to 1
- `2.0.1` - Major version bump

### How to Customize Versioning

**To change version format:**

1. Edit **2-deploy-test.yml** (line ~50)
   ```yaml
   - name: Set Version
     run: |
       echo "VERSION=1.0.${{ github.run_number }}" >> $GITHUB_ENV
   ```

2. Edit **3-deploy-production.yml** - Same location

**To use date-based versioning instead:**
   ```yaml
   - name: Set Version
     run: |
       echo "VERSION=$(date +%Y.%m.%d).${{ github.run_number }}" >> $GITHUB_ENV
   ```

**To manually increment major/minor:**
1. Edit workflows and change template: `1.0.` → `1.1.`
2. Create new Git tag: `git tag v1.1.0`
3. Push tag: `git push origin v1.1.0`

---

## Artifact Management

### Current Retention Policy

| Artifact Type | Retention (Days) | Used By | Notes |
|---------------|------------------|---------|-------|
| Solution Exports | 30 | Development | Keeps PR validation results |
| PR Validation | 30 | Developers | For reference during review |
| TEST Deployment | 90 | QA/Testing | Keeps managed solutions longer |
| PROD Deployment | 365 | Compliance | Full year audit trail |
| Reports | 90 | Monitoring | Health checks, monitoring data |

### Artifact Locations in GitHub

**Artifacts Tab:**
- GitHub repository → Actions → Workflow runs → Successfully completed runs → Artifacts
- Each artifact is available for 30-365 days (see table above)

### How to Customize Retention

**Edit retention in workflows:**

1. **PR Validation Artifacts (1-pr-validation.yml)**
   ```yaml
   - uses: actions/upload-artifact@v3
     with:
       retention-days: 30  # Change this number
   ```

2. **Deployment Artifacts (2-deploy-test.yml, 3-deploy-production.yml)**
   ```yaml
   - uses: actions/upload-artifact@v3
     with:
       retention-days: 90  # or 365 for production
   ```

---

## Deployment Configuration

### Timeouts (in minutes)

| Operation | Timeout | Location | Adjustable |
|-----------|---------|----------|-----------|
| Export Solution | 10 | All workflows | Yes, set `timeout-minutes` |
| Pack Solution | 5 | Deploy workflows | Yes |
| Import Solution | 15 | Deploy workflows | Yes |
| Smoke Tests | 10 | 2-deploy-test.yml | Yes |
| Health Checks | 10 | 6-health-check.yml | Yes |

### Backup Configuration

| Setting | Current | Purpose |
|---------|---------|---------|
| Pre-Deploy Backup | Enabled | Backup before TEST deploy |
| Production Backup | Enabled (3-phase) | Phase 1: Current state, Phase 2: Pre-import, Phase 3: Post-import |
| Backup Retention | 30 days | Auto-cleanup old backups |
| Backup Naming | `backup-{env}-{timestamp}` | Identifies environment and time |

### Smoke Tests (TEST Deployment)

**Current Tests:**
- Basic form loading
- Navigation between screens
- Test data operations
- Cloud flow execution

**Location:** 2-deploy-test.yml (lines ~180-220)

### How to Customize Deployment

**Increase timeout for slow solutions:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Increase from default
```

**Skip smoke tests for maintenance deployments:**
```yaml
run: |
  if [[ "${{ github.event.inputs.skip_tests }}" != "true" ]]; then
    # Run test commands
  fi
```

**Disable backup for testing:**
```yaml
- name: Disable Backup
  env:
    SKIP_BACKUP: true  # Set to skip backup
```

---

## Branch Configuration

### Current Branch Naming Convention

**Pattern:** `type/project-code/issue-id/description`

**Types:**
- `feature/` - New functionality
- `bugfix/` - Bug fixes
- `hotfix/` - Urgent production fixes
- `release/` - Release preparation
- `chore/` - Non-code changes (docs, config)

**Examples:**
```
feature/crm-001/US-1234/customer-dashboard
bugfix/hr-002/BUG-567/payroll-calculation-fix
hotfix/sales-001/INC-123/urgent-critical-patch
release/ops-003/REL-001/v1.2.0-prepare
chore/fin-004/CHO-001/update-documentation
```

### Main Branches (No PR Required)

| Branch | Purpose | Auto-Deploy |
|--------|---------|------------|
| `main` | Production releases | No (requires 2 approvals) |
| `develop` | Integration/staging | Yes (deploys to TEST) |

### Branch Protection Rules

**Set in GitHub:** Settings → Branches → Branch protection rules

| Setting | Main | Develop | Release/* |
|---------|------|---------|-----------|
| Require PR reviews | 2 | 1 | 1 |
| Status checks | Required | Required | Required |
| CODEOWNERS review | Yes | No | No |
| Dismiss stale reviews | Yes | Yes | Yes |
| Require up-to-date | Yes | Yes | Yes |

### How to Customize Branches

**Change main branch from `main` to `master`:**
1. Edit **3-deploy-production.yml** (line ~10)
   ```yaml
   on:
     push:
       branches: [master]  # Change from main
   ```
2. Edit GitHub repository settings
3. Make all new releases to `master`

**Add another deployment branch:**
1. Edit **2-deploy-test.yml**
   ```yaml
   on:
     push:
       branches: [develop, staging]  # Add staging
   ```
2. Create branch protection rule for `staging`

---

## Notification Configuration

### Slack Webhook Setup

**Webhooks Stored in GitHub Secrets:**

| Secret Name | Purpose | Alert Level |
|-------------|---------|------------|
| `SLACK_WEBHOOK` | General notifications | Info/Warning |
| `SLACK_WEBHOOK_CRITICAL` | Urgent alerts | Critical/Error |

**To create Slack webhook:**
1. Go to Slack workspace settings
2. Create Incoming Webhook integration
3. Copy webhook URL
4. Store in GitHub Secrets (Settings → Secrets)

### Current Notification Triggers

| Event | Webhook | Enabled | Channel |
|-------|---------|---------|---------|
| PR Validation Complete | Default | Yes | #deployments |
| TEST Deployment Success | Default | Yes | #deployments |
| TEST Deployment Failure | Critical | Yes | #alerts |
| PROD Deployment Start | Critical | Yes | #deployments |
| PROD Deployment Success | Critical | Yes | #deployments |
| PROD Deployment Failure | Critical | Yes | #alerts |
| Rollback Started | Critical | Yes | #incidents |
| Health Check Failed | Critical | Yes | #alerts |

### How to Customize Notifications

**Add new Slack channel:**
1. Create channel in Slack
2. Create webhook for that channel (workspace settings → Incoming Webhooks)
3. Store webhook URL in GitHub Secrets (e.g., `SLACK_WEBHOOK_OPS`)
4. Add step in workflow (e.g., 5-maintenance.yml):
   ```yaml
   - uses: slackapi/slack-github-action@v1
     with:
       webhook-url: ${{ secrets.SLACK_WEBHOOK_OPS }}
       payload: |
         {
           "text": "Maintenance Status: Complete"
         }
   ```

**Disable notifications:**
```yaml
- name: Skip Slack Notification
  if: ${{ failure() }}
  # Skips this step if previous steps succeeded
```

---

## Approval Gate Configuration

### Production Deployment Approvals

**2-Person Approval Gates:**

1. **Security Approval** (Environment: `production-security`)
   - Gateway: Initial security review
   - Required: 1 approver from security team
   - Timeout: 7 days

2. **Release Approval** (Environment: `production-release`)
   - Gateway: Final release authorization
   - Required: 1 approver from release managers
   - Timeout: 7 days

**Setup in GitHub:**
1. Settings → Environments → New environment
2. Name: `production-security`
3. Add environment secret: `ENVIRONMENT_URL_PROD`
4. Add required reviewers (Security team)
5. Set timeout: 7 days
6. Repeat for `production-release`

### Rollback Approval Gate

| Setting | Value | Notes |
|---------|-------|-------|
| Environment | `rollback-approval` | Separate from deploy gates |
| Required Approvers | 1 | Incident commander |
| Timeout | 1 day | Urgent |
| Auto-trigger | Manual dispatch | User initiates via GitHub Actions UI |

### How to Customize Approvals

**Add another approval layer:**
1. Create new environment: `production-compliance`
2. Edit **3-deploy-production.yml** (line ~70):
   ```yaml
   - uses: step-security/wait-for-secrets@v1
     with:
       secrets-context: ${{ secrets }}
       known-secret-types: github-token
       timeout-minutes: 10080  # 7 days
   ```

**Skip approvals for emergency hotfixes:**
```yaml
jobs:
  approve_security:
    environment: 
      name: production-security
      # Skip if emergency: true
    if: ${{ github.event.inputs.emergency != 'true' }}
```

---

## Monitoring & Health Check Configuration

### Health Check Schedule

| Check | Schedule | Timezone | Frequency |
|-------|----------|----------|-----------|
| Morning Check | 8:00 AM | UTC | Daily |
| Evening Check | 8:00 PM | UTC | Daily |
| Maintenance | 2:00 AM Sunday | UTC | Weekly |
| Monitoring Report | 6:00 AM 1st | UTC | Monthly |
| Provisioning | 3:00 AM Monday | UTC | Weekly |

### Health Check Metrics

**Monitored per Environment:**
- Environment availability (online/offline)
- API response time (target: <2000ms)
- Database size usage
- Plugin execution performance
- Flow success rate
- Connector health status

**Configuration Location:** 6-health-check.yml (lines ~50-150)

### Monitoring Report Sections

| Section | Frequency | Includes |
|---------|-----------|----------|
| Solution Size | Monthly | Total size, growth trend |
| Component Analysis | Monthly | Count by type, growth |
| Performance Metrics | Monthly | Flow execution time, plug-in execution |
| Dependency Analysis | Monthly | External dependencies, health |
| Governance Compliance | Monthly | Compliance status, issues |
| Technical Debt | Monthly | Code quality issues, recommendations |

**Configuration Location:** 7-solution-monitoring.yml (lines ~80-120)

### How to Customize Monitoring

**Change health check time:**
Edit **6-health-check.yml** (line ~5):
```yaml
schedule:
  - cron: '0 10 * * *'  # Change from 8 AM to 10 AM
  - cron: '0 22 * * *'  # Change from 8 PM to 10 PM
```

**Add new metric to health checks:**
1. Edit **6-health-check.yml** (line ~150)
2. Add new PowerShell script section:
   ```powershell
   # Get new metric
   $metric = Get-PowerPlatformMetric -EnvironmentId $envId
   ```

**Increase monitoring report frequency to weekly:**
Edit **7-solution-monitoring.yml** (line ~5):
```yaml
schedule:
  - cron: '0 6 * * 1'  # Weekly on Monday at 6 AM
```

---

## Security Configuration

### Secret Scanning (TruffleHog)

| Setting | Value | Purpose |
|---------|-------|---------|
| Enabled | Yes | All PR validations |
| Tool | TruffleHog | Detects exposed credentials |
| Severity | HIGH | Fails on high-severity findings |
| Location | 1-pr-validation.yml | Line ~120 |

### MFA Requirement

- Enabled for all Azure Service Principals
- Required for production approvals
- Enforced via GitHub Environments settings

### Credential Validation

- Service Principal authentication verified in all workflows
- Credentials expire after 1 year (set reminder for renewal)
- No credentials hardcoded in workflows (all in GitHub Secrets)

### How to Rotate Secrets

**Quarterly Rotation (Recommended):**

1. **Create new Service Principal:**
   ```
   az ad app create --display-name "PowerPlatform-CICD-New"
   az ad sp create --id {app-id}
   az ad sp credential create --sp-object-id {sp-id}
   ```

2. **Update GitHub Secrets:**
   - Settings → Secrets → Update CLIENT_ID, CLIENT_SECRET
   - Verify new deployment works

3. **Delete old Service Principal:**
   ```
   az ad app delete --id {old-app-id}
   ```

### How to Enable MFA on Service Principal

1. Requires Azure privileged role (Global Admin, Privileged Role Admin)
2. In Azure Portal: Azure Active Directory → App registrations
3. Select CICD Service Principal → Certificates & Secrets
4. Add certificate (requires Azure Key Vault setup)
5. Update GitHub Secret CLIENT_SECRET to use certificate reference

---

## PR Validation Configuration

### Validation Steps (Automatic)

| Check | Enabled | Tool | Fail If Issues |
|-------|---------|------|----------------|
| Branch Name Validation | Yes | Regex | Yes |
| Solution Checker | Yes | Microsoft | Configurable |
| Code Quality | Yes | Built-in | No (warning only) |
| Security Scan | Yes | TruffleHog | Yes |
| Size Check | Yes | Built-in | Yes (>95MB) |

### Solution Checker Settings

**Current Configuration:**
- Severity Level: Medium
- Fail on issues: No (warning only)
- Max time allowed: 10 minutes
- Report URL: Included in PR comment

**To enable fail-on-issue:**
Edit **1-pr-validation.yml** (line ~70):
```yaml
- name: Check solution checker results
  run: |
    if [[ $checkerResult == "HasIssues" ]]; then
      exit 1  # Fail the check
    fi
```

### Size Thresholds

| Limit | Current | Warning At |
|-------|---------|------------|
| Max Solution Size | 95 MB | 80 MB |
| Max File Size | 25 MB | 20 MB |

**To adjust thresholds:**
Edit **1-pr-validation.yml** (line ~100):
```bash
if (( $size > 95 )); then
  echo "Solution size exceeds 95 MB - FAIL"
  exit 1
fi
```

### PR Comment Format

**Location:** 1-pr-validation.yml (lines ~150-200)

**Includes:**
- ✅/❌ All validation check results
- Branch name feedback
- Solution Checker findings
- Size analysis
- Recommendations

### How to Customize PR Validation

**Add new check:**
1. Edit **1-pr-validation.yml**
2. Add new step before "Create validation summary"
3. Export result to GitHub output
4. Include in summary comment

**Skip validation for certain branches:**
```yaml
jobs:
  pr-validation:
    if: contains(fromJson('["develop", "main"]'), github.base_ref) == false
```

---

## Advanced Configuration

### Concurrency Settings

**Purpose:** Prevents simultaneous deployments to same environment

**Current Setting:**
```yaml
concurrency:
  group: deploy-${{ matrix.environment }}  # Groups by environment
  cancel-in-progress: true  # Cancels older run if new starts
```

**When this helps:**
- Multiple developers push to `develop` simultaneously
- Multiple hotfixes to `main` queued up
- Prevents race conditions on solution import

### Retry Settings

| Component | Max Attempts | Wait Time |
|-----------|-------------|-----------|
| Import Solution | 2 | 10 seconds |
| Export Solution | 2 | 10 seconds |
| API Calls | 3 | 5 seconds |

**Edit retry (example 2-deploy-test.yml):**
```yaml
- name: Import Solution
  run: |
    for i in 1 2 3; do
      if import-solution; then
        break
      fi
      sleep 10
    done
```

### Dry Run Mode

**Purpose:** Test workflow logic without making actual changes

**Current:** Disabled

**To enable:**
1. Add GitHub Actions input to workflow
2. Add conditional step checks

---

## Critical GitHub Setup

### Required GitHub Secrets (6 Total)

**In GitHub Repository → Settings → Secrets and variables → Actions**

```
TENANT_ID          = Your Azure Tenant ID (UUID format)
CLIENT_ID          = Service Principal Application ID
CLIENT_SECRET      = Service Principal Password/Certificate
ENVIRONMENT_URL_DEV    = https://[org]-dev.crm.dynamics.com/
ENVIRONMENT_URL_TEST   = https://[org]-test.crm.dynamics.com/
ENVIRONMENT_URL_PROD   = https://[org]-prod.crm.dynamics.com/
```

### Required GitHub Environments (2 Total)

**In GitHub Repository → Settings → Environments**

| Environment | Purpose | Required Reviewers | Timeout |
|-------------|---------|------------------|---------|
| `production-security` | Security approval gate | 1 (Security team) | 7 days |
| `production-release` | Release approval gate | 1 (Release mgr) | 7 days |

### Required Branch Protection Rules

**In GitHub Repository → Settings → Branches**

| Branch | Rule |
|--------|------|
| `main` | ✅ Require 2 PR approvals |
| `develop` | ✅ Require 1 PR approval |
| Release/* | ✅ Require 1 PR approval |

### Required CODEOWNERS File

**Location:** `.github/CODEOWNERS`

**Current assignments:**
- `* @devops-team` - Default (all files)
- `.github/workflows/* @devops-team` - Workflow changes
- `docs/* @solution-owners` - Documentation

---

## How to Customize

### 5-Minute Changes

1. **Change Slack channel:**
   - Get new webhook URL
   - Update `SLACK_WEBHOOK` secret
   - Done - next workflow uses new channel

2. **Change environment URL:**
   - Update `ENVIRONMENT_URL_DEV` (or appropriate env)
   - Done - workflows use new URL on next run

3. **Change health check time:**
   - Edit workflow file
   - Modify schedule cron expression
   - Commit and push

### 30-Minute Changes

1. **Add new monitoring metric:**
   - Edit 6-health-check.yml
   - Add PowerShell script to retrieve metric
   - Add metric to report output
   - Test locally first

2. **Change artifact retention:**
   - Edit retention-days in all deploy workflows
   - Commit and push
   - Apply to future artifacts (existing not affected)

3. **Add new validation check:**
   - Edit 1-pr-validation.yml
   - Add check step with output variable
   - Include in PR comment summary
   - Test with new PR

### 1-Hour+ Changes

1. **Restructure workflows (e.g., add environment):**
   - Update all 8 workflow files
   - Update GitHub Secrets
   - Update branch protection rules
   - Create GitHub Environment
   - Test end-to-end

2. **Change versioning strategy:**
   - Edit 2-deploy-test.yml version template
   - Edit 3-deploy-production.yml version template
   - Update release creation to use new format
   - Update any documentation

3. **Add approval layer:**
   - Create new GitHub Environment
   - Add required reviewers
   - Add wait-for-approval step to workflow
   - Set timeout
   - Test with real deployment

### Anti-Patterns (Don't Do This)

❌ **DO NOT:** Hardcode secrets in workflow files
   - Always use GitHub Secrets (`${{ secrets.SECRET_NAME }}`)

❌ **DO NOT:** Commit `.env` files
   - They're in `.gitignore` for security
   - Use GitHub Secrets instead

❌ **DO NOT:** Disable security checks for "speed"
   - Security checks take <5 minutes
   - Worth the protection

❌ **DO NOT:** Skip backups in production
   - Backups enabled in 3-deploy-production.yml for reason
   - Disable only temporarily with `inputs.skip_backup`

❌ **DO NOT:** Log sensitive values
   - Add `## Mask values` in workflow debug
   - Use `if: failure()` for sensitive logs

---

## Configuration Change Checklist

When making configuration changes, use this checklist:

- [ ] Edit configuration section(s) in affected workflow(s)
- [ ] Test changes in isolation (if possible)
- [ ] Commit changes with clear message
- [ ] Push to feature branch for review
- [ ] Merge to develop for TEST deployment
- [ ] Monitor TEST deployment for issues
- [ ] Merge to main for PROD deployment (with approvals)
- [ ] Document change in this guide
- [ ] Notify team via Slack about changes

---

## Quick Reference Commands

### Test a workflow locally
```bash
# Install act (GitHub Actions local runner)
brew install act

# Run workflow
act push --job deploy-test --secret-file my.secrets

# Run specific workflow file
act -j pr-validation
```

### Get workflow run details
```bash
# List recent runs
gh run list

# View specific run
gh run view {run_id}

# View logs
gh run view {run_id} --log
```

### Manual workflow trigger
```bash
# View inputs for workflow
gh workflow view 8-provisioning.yml

# Trigger workflow dispatch
gh workflow run 8-provisioning.yml \
  --ref main \
  --raw-field skip_tests=true
```

### Update GitHub Secrets
```bash
# Add/update secret
gh secret set SECRET_NAME --body "secret_value"

# List secrets
gh secret list

# Delete secret (if needed)
gh secret delete SECRET_NAME
```

---

## Support & Troubleshooting

**Common Issues:**

1. **Workflows not triggering:**
   - Check branch protection rules allow workflow commits  
   - Verify Secret names match exactly (case-sensitive)
   - Confirm GitHub Actions enabled (Settings → Actions)

2. **Deployment failures:**
   - Check environment URL is correct
   - Verify Service Principal has required permissions
   - Review workflow logs for specific error

3. **Approval gates timing out:**
   - Check timeout set to reasonable value (7+ days recommended)
   - Verify required reviewers are correct team members
   - Ensure reviewers have GitHub access

**For help:**
- See GitHub-Setup-Guide.md for comprehensive setup
- See Developer-Workflow-Guide.md for usage
- See Quick-Reference-Guide.md for command reference

