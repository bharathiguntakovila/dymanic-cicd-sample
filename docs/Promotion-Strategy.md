# Power Platform Solution Promotion Strategy

## Overview

This document explains how to promote Power Platform solutions from development through QA, CAT (Customer Acceptance Testing), to Production using GitHub Actions and the Git Flow branching strategy.

### Key Concepts

**Your Development Environment (DEV):**
- This is your Dynamics 365/Power Platform org where developers build
- Changes are made directly in this org
- The `power-platform-export-extract.yml` workflow **exports** changes from this org to git
- This makes your DEV org **the source of truth for first capture**

**Git Repository (Source Control):**
- Stores all solution components as human-readable XML/JSON
- Acts as the **source of truth for promotion**
- Branches control what gets promoted where

**Other Environments (QA, CAT, PROD):**
- These receive solutions via **import** workflows
- They don't make direct changes (changes should go back to DEV)
- Each has an approval gate for safety

## Environment Mapping

| Environment | Git Branch | Workflow | Purpose |
|---|---|---|---|
| **Dev (your org)** | `develop` | power-platform-export-extract | Export solutions, source of truth |
| **QA** | `qa` | 1-deploy-qa | Auto-deploy after push |
| **CAT** | `cat` | 2-deploy-cat | Manual approval required |
| **Production** | `main` | 3-deploy-production | Manual approval + backup |

## Feature Branch Workflow (Development)

All feature work happens in **feature branches** off `develop`:

```
git checkout develop
git pull origin develop
git checkout -b feature/crm/US-1234/dashboard-control
# ... make changes in Power Platform Dev environment ...
# ... commit changes when ready ...
git add .
git commit -m "feat: Add new dashboard control"
git push origin feature/crm/US-1234/dashboard-control
```

**Create Pull Request** on GitHub:
- From: `feature/crm/US-1234/dashboard-control`
- To: `develop`
- Require code review and approval before merge

Once approved and merged to `develop`, the **export-extract workflow** will:
1. Export your changes from DEV environment
2. Unpack solution to `solutions/Samlab/` in git
3. Commit export to git repository

This makes `develop` branch your source of truth with all solution components as XML/JSON files.

## Promotion Flow (Step-by-Step)

```
Feature Branches (feature/crm/US-*/)
      ↓ (Pull Request)
  develop branch
      ↓ (All solutions in git)
  power-platform-export-extract.yml ← DEVELOPMENT WORKFLOW
      ↓ (Exports from DEV environment, commits to git)
[Solutions available in git as XML/JSON]
      ↓ (Merge or rebase to next branch)
    qa branch
      ↓ (Auto-deploy on push)
  1-deploy-qa.yml (Imports to QA environment)
      ↓ (Merge or rebase after testing)
   cat branch
      ↓ (Auto-deploy on push)
  2-deploy-cat.yml (Imports to CAT environment) [⚠️ Approval Gate]
      ↓ (Merge or rebase after UAT)
   main branch
      ↓ (Auto-deploy on push)
3-deploy-production.yml (Imports to Production) [⚠️ Approval Gate + Backup]
```

## Workflow Files

### 0. **power-platform-export-extract.yml** (Development - DEV Environment)
- **Trigger:** Manual trigger or scheduled
- **Branch:** `develop`
- **Source Environment:** DEV (your org)
- **Action:**
  - Exports solution from DEV environment (both managed & unmanaged versions)
  - Unpacks unmanaged solution to human-readable XML/JSON in `solutions/Samlab/`
  - Stores managed backup in `managed-solutions/`
  - Commits ALL solution components to git automatically
- **Purpose:** Makes your DEV environment changes available to all other environments as source code
- **Configuration:**
  - `ENVIRONMENT_URL`: Your DEV environment URL
  - `SOLUTION_NAME`: "Samlab"

**When to Use:**
1. After merging feature branch to `develop`
2. After making manual changes in DEV (to sync to git)
3. Or run manually via GitHub Actions: "Export and Extract Power Platform Solution"

**Output:**
- `solutions/Samlab/` - Unpacked solution source (XML/JSON)
- `managed-solutions/Samlab_managed.zip` - Backup of managed solution

### 1. **1-deploy-qa.yml** (QA Deployment)
- **Trigger:** Auto-trigger on push to `qa` branch
- **Branch:** `qa`
- **Action:**
  - Reads unpacked solution from git
  - Packs it into ZIP format
  - Imports to QA environment
- **Configuration:**
  - `QA_ENVIRONMENT_URL`
  - `QA_APP_ID`
  - `QA_CLIENT_SECRET`
  - `QA_TENANT_ID`

**To Deploy to QA:**
- Create/push to `qa` branch (or merge from develop)
- Workflow runs automatically
- Monitor in GitHub Actions tab

### 2. **2-deploy-cat.yml** (CAT Deployment)
- **Trigger:** Auto-trigger on push to `cat` branch
- **Branch:** `cat`
- **Approval:** **REQUIRES MANUAL APPROVAL** ⚠️
- **Action:**
  - Same as QA but imports to CAT environment
- **Configuration:**
  - `CAT_ENVIRONMENT_URL`
  - `CAT_APP_ID`
  - `CAT_CLIENT_SECRET`
  - `CAT_TENANT_ID`

**To Deploy to CAT:**
1. Create/push to `cat` branch (or merge from qa)
2. Workflow pauses at approval gate
3. Team member with admin rights must approve in GitHub
4. Deployment proceeds after approval

### 3. **3-deploy-production.yml** (Production Deployment)
- **Trigger:** Auto-trigger on push to `main` branch
- **Branch:** `main`
- **Approval:** **REQUIRES MANUAL APPROVAL** ⚠️
- **Action:**
  - Creates backup of current production solution
  - Imports new solution to PRODUCTION
- **Configuration:**
  - `PROD_ENVIRONMENT_URL`
  - `PROD_APP_ID`
  - `PROD_CLIENT_SECRET`
  - `PROD_TENANT_ID`

**To Deploy to Production:**
1. Merge to `main` branch (via PR with approvals)
2. Workflow pauses at approval gate
3. **ONLY** team leads/release managers should approve
4. Deployment proceeds after approval
5. Backup is created and saved in artifacts (90 days retention)

## GitHub Secrets Setup

You need to configure these secrets in GitHub Settings → Secrets:

### For QA:
```
QA_ENVIRONMENT_URL     = https://qa.crm.dynamics.com/
QA_APP_ID              = <service-principal-app-id>
QA_CLIENT_SECRET       = <service-principal-secret>
QA_TENANT_ID           = <azure-tenant-id>
```

### For CAT:
```
CAT_ENVIRONMENT_URL    = https://cat.crm.dynamics.com/
CAT_APP_ID             = <service-principal-app-id>
CAT_CLIENT_SECRET      = <service-principal-secret>
CAT_TENANT_ID          = <azure-tenant-id>
```

### For Production:
```
PROD_ENVIRONMENT_URL   = https://prod.crm.dynamics.com/
PROD_APP_ID            = <service-principal-app-id>
PROD_CLIENT_SECRET     = <service-principal-secret>
PROD_TENANT_ID         = <azure-tenant-id>
```

## Common Workflows

### Scenario 1: Create & Merge Feature Branch
```bash
# 1. Start from develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/crm/US-1234/new-control

# 3. Make changes in Power Platform dev environment
# (Customize the solution in your DEV org directly)

# 4. Commit whenever git changes sync
git add .
git commit -m "feat: Add new control to dashboard"
git push origin feature/crm/US-1234/new-control

# 5. Create PR in GitHub and get approval
# (https://github.com/your-repo/pull/new/feature/crm/US-1234/new-control)

# 6. Once approved, merge PR to develop
# This triggers auto-export of your changes!
```

### Scenario 2: Promote develop → qa → CAT → main
```bash
# After feature merged and exported to develop:

# 1. Merge develop changes to qa branch
git checkout qa
git pull origin qa
git rebase develop
git push origin qa
# → Triggers 1-deploy-qa.yml automatically

# 2. After QA testing passes, merge to cat branch
git checkout cat
git pull origin cat
git rebase qa
git push origin cat
# → pauses at approval gate

# 3. Team approves in GitHub Actions
# Go to Actions tab → 2-deploy-cat → Approve
# → Triggers 2-deploy-cat.yml

# 4. After CAT testing passes, merge to main branch
git checkout main
git pull origin main
git rebase cat
git push origin main
# → pauses at approval gate

# 5. Release manager approves in GitHub
# Go to Actions tab → 3-deploy-production → Approve
# → Triggers 3-deploy-production.yml

# 6. Solution deployed to production with backup
```

### Scenario 3: Promote from CAT → Production
```bash
# 1. Ensure cat branch is tested and released
git checkout main
git pull origin main
git rebase cat
git push origin main

# 2. At approval gate, ONLY release managers/leads approve in GitHub
# Go to Actions tab → 3-deploy-production → Approve

# 3. Deployment runs, backup created, solution deployed to production
```

## Environment Approval Rules

**GitHub Settings → Environments:**

### CAT Environment
- **Name:** CAT
- **Required Reviewers:** Team leads, QA manager
- **Deploy branches:** `cat`

### Production Environment
- **Name:** Production
- **Required Reviewers:** Release manager, CTO
- **Deploy branches:** `main`

## Rollback Procedure

### If deployment to QA/CAT fails:
1. Check GitHub Actions logs for error
2. Fix the issue in code
3. Push fix to branch again (auto-redeployment)

### If deployment to Production fails:
1. Check the production-deployment-artifacts in GitHub Actions
2. Backup is available if needed
3. Manually restore from backup or fix and rerun

## Best Practices

### ✅ DO:
- Always test in QA before promoting to CAT
- Always test in CAT before promoting to Production
- Write meaningful commit messages
- Use pull requests for branch merges
- Require code review before merging to main
- Document changes in commit messages

### ❌ DON'T:
- Merge directly to main without PR review
- Deploy to production without CAT testing
- Skip the approval gates
- Change production secrets locally
- Manual solution edits in production (always deploy via git)

## Troubleshooting

### "Solution directory not found"
- Ensure `solutions/Samlab/` exists in git
- Run export workflow first to create it

### "Authentication failed"
- Verify secrets are correct in GitHub Settings
- Check service principal has Systemadministrator role
- Verify application ID hasn't changed

### "Import failed in QA"
- Check for conflicting solutions in QA
- Verify solution dependencies are met
- Review workflow logs for PAC CLI errors

### "Approval gate not appearing"
- Ensure environment is configured in GitHub Settings
- Check branch protection rules
- Verify user has admin permissions

## Monitoring & Logging

Each workflow provides extensive logging:
- `[STEP]` - Current step being executed
- `[INFO]` - Informational messages
- `[SUCCESS]` - Successful operations
- `[WARNING]` - Non-critical issues
- `[ERROR]` - Failures requiring attention
- `[CRITICAL]` - Production-related messages

Artifacts are retained for:
- QA: 30 days
- CAT: 30 days
- Production: 90 days (includes backups)

## References

- [Git Flow Branching Model](https://nvie.com/posts/a-successful-git-branching-model/)
- [Power Apps CLI (PAC)](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Power Platform Solution Deployment](https://learn.microsoft.com/en-us/power-platform/alm/implement-alm)
