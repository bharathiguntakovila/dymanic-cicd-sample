# 🗂️ CI/CD Integration - Quick Reference Checklist

**Print this and check off as you complete each phase**

---

## ⚡ Quick Start (15 Minute Version)

If you're in a hurry, do this minimum setup:

```
Phase 1: Azure AD Service Principal (5 min)
├─ [ ] Create App Registration in Azure AD
├─ [ ] Copy: TENANT_ID, CLIENT_ID
├─ [ ] Create client secret → Copy CLIENT_SECRET
└─ [ ] Grant Dataverse API permissions

Phase 2: GitHub Secrets (5 min)
├─ [ ] Add TENANT_ID to GitHub Secrets
├─ [ ] Add CLIENT_ID to GitHub Secrets
├─ [ ] Add CLIENT_SECRET to GitHub Secrets
├─ [ ] Add ENVIRONMENT_URL_TEST to GitHub Secrets
└─ [ ] Add ENVIRONMENT_URL_PROD to GitHub Secrets

Phase 3: Service Principal Setup (3 min)
├─ [ ] Add service principal to TEST environment as Environment Admin
├─ [ ] Add service principal to PROD environment as Environment Admin
└─ [ ] Wait 5-10 minutes for permissions to apply

Phase 4: First Test (2 min)
├─ [ ] Create feature branch in GitHub
├─ [ ] Push a small change to solution
├─ [ ] Create Pull Request
└─ [ ] Watch workflow run in Actions tab
```

**Result:** Your first workflow should complete successfully ✅

---

## 📋 Complete Setup Checklist (45 Minutes)

### PHASE 1: POWER PLATFORM ENVIRONMENTS ⏱️ (15 min)

**Development Environment**
- [ ] Created at: `https://[org]-dev.crm.dynamics.com`
- [ ] Type: Developer Sandbox ✅
- [ ] Status: Ready to use
- [ ] Note: URL: _____________________

**Test Environment**
- [ ] Created at: `https://[org]-test.crm.dynamics.com`
- [ ] Type: Sandbox (not Developer) ✅
- [ ] Status: Ready to use
- [ ] Note: URL: _____________________

**Production Environment**
- [ ] Exists at: `https://[org]-prod.crm.dynamics.com`
- [ ] Type: Production ✅
- [ ] Status: Ready to use
- [ ] Note: URL: _____________________

---

### PHASE 2: GITHUB REPOSITORY ⏱️ (5 min)

**Repository Setup**
- [ ] Repository created on GitHub
- [ ] Repo name: _____________________
- [ ] URL: https://github.com/[org]/[repo]
- [ ] Visibility: Private / Public (choose one)
- [ ] Cloned locally: `git clone [url]`

**Workflow Files Added**
- [ ] `.github/workflows/1-pr-validation.yml` ✅
- [ ] `.github/workflows/2-deploy-test.yml` ✅
- [ ] `.github/workflows/3-deploy-production.yml` ✅
- [ ] `.github/workflows/4-rollback.yml` ✅
- [ ] `.github/workflows/5-maintenance.yml` ✅
- [ ] `.github/workflows/6-health-check.yml` ✅
- [ ] `.github/workflows/7-solution-monitoring.yml` ✅
- [ ] `.github/workflows/8-provisioning.yml` ✅
- [ ] `.github/config.variables.yml` ✅
- [ ] `/src/` directory (with unpacked solution) ✅

**Initial Commit**
- [ ] Files committed: `git commit -m "Initial CI/CD setup"`
- [ ] Pushed to main branch: `git push origin main`
- [ ] Visible on GitHub: All workflow files appear in `.github/workflows/`

---

### PHASE 3: AZURE AD - SERVICE PRINCIPAL ⏱️ (10 min)

**Create Application Registration**
- [ ] Navigated to Azure Portal → Azure AD
- [ ] Created new App Registration
- [ ] Name: "Power Platform CI/CD Service"
- [ ] Recorded **Application (client) ID:** ____________________
- [ ] Recorded **Directory (tenant) ID:** ____________________

**Create Client Secret**
- [ ] Created new client secret
- [ ] Expires: 24 months
- [ ] Recorded **Client secret value:** __________________ (keep safe!)

**Grant Permissions**
- [ ] Added API permission: **Microsoft Dataverse**
- [ ] Permission type: **Delegated permissions**
- [ ] Selected: `user_impersentation`
- [ ] Granted admin consent ✅
- [ ] Waited 5-10 minutes for permissions to apply

---

### PHASE 4: GITHUB SECRETS ⏱️ (10 min)

**Navigate to Secrets**
- [ ] Went to GitHub repository → Settings
- [ ] Clicked: Secrets and variables → Actions
- [ ] Ready to add secrets

**Add All Required Secrets**

| Secret Name | Value | Status |
|------------|-------|--------|
| TENANT_ID | From Azure AD | ✅ |
| CLIENT_ID | From Azure AD | ✅ |
| CLIENT_SECRET | From Azure AD | ✅ |
| ENVIRONMENT_URL_DEV | `https://[org]-dev.crm.dynamics.com` | ✅ |
| ENVIRONMENT_URL_TEST | `https://[org]-test.crm.dynamics.com` | ✅ |
| ENVIRONMENT_URL_PROD | `https://[org]-prod.crm.dynamics.com` | ✅ |

**Optional Nexus Secrets** (if using artifact storage)

| Secret Name | Value | Status |
|------------|-------|--------|
| NEXUS_URL | https://nexus.yourcompany.com | ⭕ |
| NEXUS_USERNAME | Your Nexus username | ⭕ |
| NEXUS_PASSWORD | Your Nexus password | ⭕ |

---

### PHASE 5: SERVICE PRINCIPAL - POWER PLATFORM ACCESS ⏱️ (5 min)

**For EACH environment (Dev, Test, Prod):**

**Development Environment**
- [ ] Navigated to Power Platform Admin Center
- [ ] Selected Development environment
- [ ] Clicked Settings → Users + permissions → Users
- [ ] Added "Power Platform CI/CD Service"
- [ ] Assigned role: **Environment Admin**
- [ ] Clicked Save
- [ ] Waited 5 minutes

**Test Environment**
- [ ] Navigated to Power Platform Admin Center
- [ ] Selected Test environment
- [ ] Clicked Settings → Users + permissions → Users
- [ ] Added "Power Platform CI/CD Service"
- [ ] Assigned role: **Environment Admin**
- [ ] Clicked Save
- [ ] Waited 5 minutes

**Production Environment**
- [ ] Navigated to Power Platform Admin Center
- [ ] Selected Production environment
- [ ] Clicked Settings → Users + permissions → Users
- [ ] Added "Power Platform CI/CD Service"
- [ ] Assigned role: **Environment Admin** or **Deployment Admin**
- [ ] Clicked Save
- [ ] Waited 5 minutes

---

### PHASE 6: SOLUTION IN REPO ⏱️ (5 min)

**Solution Directory Structure**
- [ ] `/src/` directory exists
- [ ] `/src/Solution.xml` exists
- [ ] Subdirectories present:
  - [ ] CanvasApps/
  - [ ] CloudFlows/
  - [ ] Entities/
  - [ ] Flows/
  - [ ] WebResources/
  - And others...

**Commit Solution**
- [ ] Executed: `git add src/`
- [ ] Executed: `git commit -m "Add solution files"`
- [ ] Executed: `git push origin main`
- [ ] Directory visible on GitHub

---

### PHASE 7: OPTIONAL - NEXUS SETUP ⏱️ (10 min)

**If not using Nexus, SKIP this phase**

**Nexus Server**
- [ ] Nexus server running at: ____________________
- [ ] Verified connectivity: `curl [nexus-url]`
- [ ] Repository "powerplatform-artifacts" exists

**Enable in Config**
- [ ] Edited `.github/config.variables.yml`
- [ ] Section 15 (Nexus): `enabled: true`
- [ ] Line 539: `nexus.enabled: true`
- [ ] Committed changes: `git push origin main`

---

### PHASE 8: FIRST WORKFLOW TEST ⏱️ (5 min)

**Feature Branch & PR**
- [ ] Created feature branch: `git checkout -b feature/test-setup`
- [ ] Made a small change to solution (or add marker file)
- [ ] Committed: `git add . && git commit -m "Test CI/CD"`
- [ ] Pushed: `git push -u origin feature/test-setup`

**GitHub PR**
- [ ] Created Pull Request on GitHub
- [ ] Title: "Test: Initial CI/CD validation"
- [ ] Submitted PR

**Workflow Execution**
- [ ] Went to Actions tab
- [ ] Saw "1-pr-validation" workflow running ✅
- [ ] Workflow completed SUCCESSFULLY ✅
- [ ] Green checkmark appeared on PR ✅

**Merge & Deploy to TEST**
- [ ] Merged PR to main branch
- [ ] Went to Actions tab
- [ ] Saw "2-deploy-test" workflow running ✅
- [ ] Waited 5-10 minutes for completion
- [ ] Workflow completed SUCCESSFULLY ✅

**Verification**
- [ ] Went to Power Platform Maker: https://make.powerapps.com
- [ ] Selected TEST environment
- [ ] Clicked Solutions
- [ ] Saw solution deployed ✅

---

### PHASE 9: VERIFY NEW FEATURES ⏱️ (2 min)

**Structured Logging (Collapsible Logs)**
- [ ] Opened workflow run
- [ ] Saw collapsible `::group::` sections
- [ ] Could expand/collapse Upload to Nexus Summary
- [ ] Logs much easier to read ✅

**Timeout Protection**
- [ ] Opened workflow run
- [ ] In job details, saw `timeout-minutes` set
- [ ] Example: `timeout-minutes: 45`
- [ ] Jobs won't hang indefinitely ✅

**Workflow Summary**
- [ ] Opened workflow run
- [ ] Scrolled to bottom
- [ ] Saw "Workflow Summary" section
- [ ] Showed deployment status, version, duration
- [ ] Professional visibility ✅

---

## ✅ Integration Complete!

When all checkboxes are checked:

🎉 **Your CI/CD is ready for production!**

### What You Can Now Do

✅ **Automated Testing**
- Every PR automatically validates the solution
- Security scanning runs on all changes
- Takes ~5-10 minutes per PR

✅ **Auto-Deploy to TEST**
- Push to main → automatically deploys to Test environment
- No manual steps needed
- Takes ~10-15 minutes per deployment

✅ **Controlled Production Deployments**
- Requires 2-person approval
- Full audit trail maintained
- 365-day artifact retention for compliance

✅ **Emergency Rollbacks**
- <15 minute recovery time
- One-click rollback to previous version
- Automated incident tracking

✅ **Weekly Maintenance**
- Automatic cleanup of old branches
- Health monitoring
- Compliance reporting

---

## 🚨 Common Issues & Fixes

### "Workflow not appearing in Actions tab"
```
❌ Cause: Workflow files not in .github/workflows/
✅ Fix: Copy workflow files to .github/workflows/ and push
```

### "Authentication failed" error
```
❌ Cause: GitHub Secrets missing or incorrect
✅ Fix: Verify all 6 secrets in Settings → Secrets and variables → Actions
```

### "Service principal has no permissions"
```
❌ Cause: Service principal not added to environments
✅ Fix: Add service principal to each environment in Power Platform Admin Center
```

### "Deployment times out after 45 minutes"
```
❌ Cause: Solution too large or network issues
✅ Fix: Increase timeout-minutes in workflow file, or optimize solution
```

---

## 📞 Support

- **Questions?** See [INTEGRATION-STARTUP-GUIDE.md](INTEGRATION-STARTUP-GUIDE.md) for detailed steps
- **Configuration?** See [CONFIGURATION-GUIDE.md](CONFIGURATION-GUIDE.md)
- **Daily Operations?** See [Developer-Workflow-Guide.md](Developer-Workflow-Guide.md)
- **Troubleshooting?** See section at end of each guide

---

**🚀 Print this checklist, check off each item, and you'll have production-ready CI/CD in 45 minutes!**

