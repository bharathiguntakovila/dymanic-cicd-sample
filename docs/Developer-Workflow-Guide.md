# 📖 Developer Workflow Guide

Quick reference for developers using the Power Platform CI/CD pipeline.

---

## 🎯 Daily Development Workflow

### 1. Create Feature Branch

```bash
# Pull latest develop
git checkout develop
git pull origin develop

# Create feature branch following naming convention:
# Type: feature|bugfix|hotfix|release|chore
# Project: 3-letter code (e.g., crm, hr, fin)
# Issue: Ticket number (e.g., US-1234)
# Description: kebab-case, 3-50 chars

git checkout -b feature/crm-001/US-1234/customer-dashboard-update

# Push to create remote tracking branch
git push -u origin feature/crm-001/US-1234/customer-dashboard-update
```

### 2. Make Changes

```bash
# Edit solution files in src/
# Keep commits small and descriptive
git add .
git commit -m "feat: add customer dashboard widget

- Displays customer KPIs
- Updates real-time
- Performance optimized"

git push origin feature/crm-001/US-1234/customer-dashboard-update
```

### 3. Create Pull Request (PR)

1. Go to GitHub repository
2. Click **Compare & pull request**
3. Fill PR template completely:
   - Link to issue
   - Describe changes
   - Check testing boxes
   - Add screenshots
4. Click **Create pull request**

**What happens automatically:**
- ✅ Branch name validated (against naming pattern)
- ✅ Solution Checker runs
- ✅ Code quality checks execute
- ✅ Security scanning scans for secrets
- ✅ Results posted in PR comments within 5-10 minutes

### 4. Address PR Feedback

```bash
# Make requested changes
# Commit with clear message
git add .
git commit -m "refactor: simplify customer KPI calculation"
git push origin feature/crm-001/US-1234/customer-dashboard-update

# Workflow re-runs automatically on new commits
```

### 5. Merge to Develop

**Requirements before merge:**
- ✅ PR validation passed (green checkmarks)
- ✅ Code review approved (1+ approver)
- ✅ All conversations resolved
- ✅ Branch is up to date with develop

**Merge:**
1. Click **Squash and merge** (or keep commits if substantial)
2. Delete branch after merge
3. Go to **Actions** tab to watch **TEST deployment** trigger

**What happens automatically:**
- ✅ TEST environment backup created
- ✅ Solution exported from dev
- ✅ Solution packed to managed format
- ✅ Managed solution deployed to TEST
- ✅ Smoke tests run automatically
- ✅ Slack notification sent to `#deployments`
- ✅ GitHub issue created for QA tracking

---

## 🧪 Testing Your Changes in TEST

### Access TEST Environment

```
Power Platform Admin Center
→ Environments
→ Select "Test" environment
→ Open
```

### Run Manual Tests

1. **Form Testing**
   - Load main form
   - Test all fields
   - Test calculations
   - Verify workflows trigger

2. **Flow Testing**
   - Manually trigger cloud flows
   - Verify flow actions execute
   - Check automation logs

3. **Integration Testing**
   - Test API calls
   - Verify data syncing
   - Check connector reliability

4. **Report Results**
   - Comment on deployment issue (auto-created)
   - Report any bugs found
   - Provide pass/fail status

### Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| Solution import fails | Check solution compatibility, retry deployment |
| Flows disabled | Enable flows in TEST environment |
| Data missing | Run test data import script |
| Performance slow | Clear browser cache, check resource usage |

---

## 🚀 Promoting to Production

### Create Release Branch

```bash
# Only release manager does this
git checkout develop
git pull origin develop

# Create release branch for version (e.g., v1.2.0)
git checkout -b release/v1.2.0
git push -u origin release/v1.2.0
```

### Finalize Release

1. Update version in solution
2. Update CHANGELOG.md
3. Commit: `chore: prepare release v1.2.0`
4. Create PR from `release/v1.2.0` to `main`
5. Obtain code review (1+ approval)
6. Merge to `main`

**What happens automatically:**
1. ✅ Pre-deployment checks run
2. ✅ **Two approval gates triggered:**
   - 🔐 Security team approves (security review)
   - 🎯 Release manager approves (releases sign-off)
3. ✅ Production environment backed up (labeled with timestamp)
4. ✅ Managed solution deployed to production
5. ✅ Post-deployment validation tests run
6. ✅ **GitHub Release created** with deployment info
7. ✅ Slack notification sent to `#deployments`
8. ✅ Team alerted of successful deployment

### Production Deployment Status

Track deployment progress:
- Go to **Actions** tab
- Click **3️⃣ Deploy to Production**
- Monitor workflow execution
- Check Slack for notifications

---

## 🚨 Emergency Rollback Procedure

**Time-boxed recovery: <15 minutes**

### When to Rollback

- 🚨 Critical bug in production
- 🔥 Data corruption detected
- ⚠️ Performance severely degraded
- 🔐 Security issue identified

### Execute Rollback

1. Go to **Actions** tab
2. Click **🔄 Rollback**
3. Click **Run workflow**
4. Select inputs:
   - **Environment:** Production
   - **Version:** Previous working version
   - **Reason:** Briefly explain (e.g., "Critical data corruption")
5. Click **Run workflow**

**What happens automatically:**
- ✅ Incident ID generated (INC-YYYYMMDD-HHMMSS)
- ✅ Current production backed up (post-mortem analysis)
- ✅ **Approval gate triggered** (prevent accidental rollback)
- ✅ Previous version deployed
- ✅ Post-rollback validation tests run
- ✅ **Post-mortem issue created** with action items
- ✅ Slack alerts sent with incident status
- ✅ Team notified immediately

### Post-Rollback Actions

1. **Immediate:** Verify production stability
2. **Within 24h:** Investigation & RCA
3. **Within 1 week:** Fix, test, and redeploy
4. **Complete:** Post-mortem issue updated with findings

---

## 👀 Monitoring Your Solution

### Check Health Status

Access daily health reports:
- **Email:** Slack notifications at 8 AM & 8 PM UTC
- **Manual:** Go to **Actions** → **🏥 Environment Health Check** → **Run workflow**

### Monitor Performance

Performance metrics tracked automatically:
- Form load times
- Query performance
- API response times
- Concurrent user count
- Storage utilization

### View Reports

Monthly reports available:
- Go to **Actions** → **📦 Solution Monitoring**
- Download `solution-monitoring-report-*.md`
- Reviews:
  - Component growth
  - Performance trends
  - Technical debt
  - User engagement

---

## 🔐 Security Best Practices

### Before Committing Code

- ✅ Never commit secrets (passwords, API keys)
- ✅ Never commit personal data
- ✅ Use `.gitignore` for sensitive files
- ✅ Use GitHub Secrets for credentials

### PR Security Checks

Workflow automatically scans for:
- 🔍 Exposed credentials
- 🔍 Hardcoded passwords
- 🔍 AWS keys, Azure secrets
- 🔍 Private keys
- 🔍 API tokens

### If Secret Exposed

1. **Immediately:**
   - Regenerate secret in Azure AD
   - Rotate environment credentials
   - Comment issue on GitHub

2. **Within 1 hour:**
   - Update GitHub Secrets
   - Verify no unauthorized access
   - Document incident

3. **Within 24 hours:**
   - Security review of exposure scope
   - Team notification
   - Preventive measures implemented

---

## 📝 Workflow Reference

### 1️⃣ PR Validation (`on: pull_request`)

Trigger: New PR or PR commit push

**Checks:**
- Branch naming validation
- Solution Checker
- Code quality
- Security scanning

**Result:** PR comment with results

**Expected Time:** 5-10 minutes

---

### 2️⃣ Deploy to TEST (`on: push to develop`)

Trigger: Merge to develop branch

**Actions:**
- Export solution from DEV
- Build managed solution
- Back up TEST environment
- Deploy to TEST
- Run smoke tests

**Result:** Slack notification + GitHub issue for QA

**Expected Time:** 10-15 minutes

---

### 3️⃣ Deploy to Production (`on: push to main + approvals`)

Trigger: Merge to main branch

**Actions:**
- Pre-deployment validation
- Security review approval gate
- Release approval gate
- Back up production
- Deploy to production
- Create GitHub Release

**Result:** GitHub Release + Slack notification

**Expected Time:** 15-20 minutes (plus approval wait time)

---

### 4️⃣ Rollback (`on: workflow_dispatch`)

Trigger: Manual activation

**Actions:**
- Create incident ID
- Back up current production state
- Approval gate for safety
- Deploy previous version
- Validate deployment
- Create post-mortem issue

**Result:** Incident tracked + team alerted

**Expected Time:** 5-10 minutes (execution only)

---

### 5️⃣ Maintenance (`schedule: Weekly`)

Trigger: Every Sunday 2 AM UTC

**Actions:**
- Clean merged branches
- Delete old artifacts
- Repository health check
- Security audit
- Generate reports

**Result:** Maintenance issue + Slack summary

---

### 6️⃣ Health Check (`schedule: Twice daily`)

Trigger: Daily at 8 AM & 8 PM UTC

**Actions:**
- Check all environment status
- Verify critical systems
- Test critical flows
- Monitor performance
- Backup verification

**Result:** Slack notification + artifact report

---

### 7️⃣ Solution Monitoring (`schedule: Monthly`)

Trigger: First day of month 6 AM UTC

**Actions:**
- Analyze solution size
- Track component growth
- Performance profiling
- Governance compliance
- Technical debt assessment

**Result:** Monthly report + GitHub issue

---

### 8️⃣ Provisioning (`on: workflow_dispatch`)

Trigger: Manual activation

**Actions:**
- Check dependency updates
- Create new dev environment
- Recreate test environment
- Clone pre-prod from prod

**Result:** Environment provisioned + notification

---

## 📞 Getting Help

### Common Questions

**Q: How long does PR validation take?**
A: 5-10 minutes typically. Check Actions tab for status.

**Q: Can I deploy directly to production?**
A: No. Must go through develop → TEST → release → main → PROD sequence. This ensures quality gates.

**Q: What if tests fail in TEST?**
A: Create new feature branch from develop, fix issues, create new PR. Don't merge broken code.

**Q: How do I know deployment status?**
A: Check Slack notifications or go to Actions tab and filter for deployment workflows.

**Q: Can I skip the approval gates?**
A: No. Approval gates are enforced for production deployments as security requirement.

### Contact

- **Technical Issues:** Tag `@devops-team` in GitHub issues
- **Power Platform Questions:** Tag `@solution-owner`
- **Access/Permissions:** Tag `@platform-architects`
- **Urgent Issues:** Slack `@devops-oncall`

---

## 🎓 Training Resources

- [Git Flow Documentation](./ALM-Architecture-Validation.md)
- [Architecture Overview](./Power-Platform-ALM.drawio)
- [Solution Checker Guide](./Quick-Reference-Guide.md)
- [GitHub Setup Steps](./GitHub-Setup-Guide.md)

---

## ✅ Checklist Before First Commit

- [ ] Cloned repository locally
- [ ] Created feature branch with correct naming
- [ ] Made changes in `/src/` directory
- [ ] Tested changes in DEV environment locally
- [ ] No sensitive data in commits
- [ ] Clear, descriptive commit messages
- [ ] PR template filled completely
- [ ] Linked to GitHub issue
- [ ] Ready for peer review

---

*Welcome to the team! Happy coding!* 🚀

---

*Last Updated: November 2024*
