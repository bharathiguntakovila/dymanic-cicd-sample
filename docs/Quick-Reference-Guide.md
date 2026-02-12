# GitHub Actions + Power Platform - Quick Reference Guide

## Environment Configuration

### Development Environment
```
Type: Developer or Sandbox (unmanaged)
Solution Type: Unmanaged
Access: Single developer + optional pair
Version Control: Git (feature/* branch)
Components Maximum: 50 (before multi-solution)
Data: Development only (no production data)
Backup: Git history (source of truth)
Reset Policy: Can be reset/recreated on demand
```

### Test Environment
```
Type: Sandbox
Solution Type: Managed (from dev build)
Access: QA/Testers + Admins (minimal privileges)
Version Control: Reference via release tag
Components Maximum: Same as dev
Deployment: Auto-triggered from develop branch merge
Backup: Power Platform Admin Center
Data: Test data only (from seeding scripts)
Purpose: End-to-end validation before prod
```

### Pre-Production (Optional)
```
Type: Production
Solution Type: Managed
Access: Release team + Admins
Version Control: Release tag (same as test version)
Components Maximum: Same as dev
Deployment: Manual via release/* branch
Purpose: Final pre-production validation
Staging: Full production simulation
Backup: Power Platform Admin Center
Recovery: Can redeploy from release tag
```

### Production Environment
```
Type: Production
Solution Type: Managed only
Access: Admins + End Users (no makers)
Version Control: Main branch releases (tagged)
Deployment: 2-person approval required
Backup: Automatic before import
Recovery: Revert to previous tag (GitHub)
RTO Target: <15 minutes
Smoke Tests: Automated post-deployment
Monitoring: ✅ Enabled
Data: Live/Production (protected)
```

---

## Git Flow Branching Quick Reference

```
├── main (MAIN PRODUCTION RELEASE)
│   ├── Tag: v1.0.0 → Prod Deploy
│   ├── Tag: v1.1.0 → Prod Deploy
│   └── Tag: v1.2.0 → Prod Deploy
│
├── develop (TEST INTEGRATION)
│   ├── Auto-deploy to TEST on merge
│   └── Base for all feature development
│
├── release/* (PRE-PRODUCTION / HOTFIX SUPPORT)
│   ├── release/v1.2.0 → Pre-Prod Deploy
│   └── Can also serve existing v1.1.0 in prod
│
├── feature/* (DEVELOPER WORK)
│   ├── feature/user-auth-ui
│   ├── feature/billing-logic
│   └── Merge to develop via PR
│
└── bugfix/* (FIXES WITH TRACEABILITY)
    ├── bugfix/login-timeout
    ├── bugfix/form-validation
    └── Merge to develop or release/* via PR
```

### When to Use Each Branch
- **main**: Stable releases only (no direct commits, merge from release/* only)
- **develop**: Integration point, all features merge here, auto-deploys to test
- **release/***: Pre-production release prep or hotfix to existing production version
- **feature/***: Individual developer feature development (one per developer/feature)
- **bugfix/***: Bug fixes with issue traceability

---

## Phase-by-Phase Workflow

### Phase 1: Development (Developer)
```
1. Create feature/task-name branch from develop
2. Open Power Apps in personal dev environment
3. Create unmanaged solution (using feature branch name)
4. Make changes via Power Apps UI
5. Auto-sync to Git (Power Platform Git Integration)
6. Publish components as needed
7. Repeat steps 4-6 until feature complete
```

### Phase 2: Pull Request & Validation (GitHub Actions)
```
1. Push feature branch to GitHub
2. Create Pull Request → develop branch
3. AUTOMATED:
   - Export solution from dev
   - Unpack solution to source files
   - Run solution checker (linting)
   - Run unit tests
   - Generate test report
4. MANUAL:
   - Code review by team
   - Approve or request changes
5. AUTOMATED (on approval):
   - Merge feature branch to develop
   - Delete feature branch
```

### Phase 3: Test Deployment (GitHub Actions)
```
1. Develop branch receives merge
2. AUTOMATED:
   - Export unmanaged solution from dev
   - Pack solution (compress, prepare)
   - Generate managed solution (build artifact)
   - Deploy to TEST environment
   - Verify import success
   - Run smoke tests
   - Generate deployment report
3. MANUAL:
   - QA team tests in test environment
   - If BUG found: Create bugfix/* branch from develop
   - If PASS: Ready for production release
```

### Phase 4: Release & Production Deployment
```
SCENARIO A: Production Release

1. Create release/v1.2.0 branch from develop
2. MANUAL: Create Release PR → main 
3. MANUAL: 2-person approval required
4. AUTOMATED (on merge to main):
   - Tag release as v1.2.0
   - Export solution from dev
   - Generate managed solution
   - Backup production environment
   - Deploy to PRODUCTION
   - Run smoke tests
5. MONITORING: Watch for errors
6. If SUCCESS: ✅ Release complete
7. If ERROR: Execute rollback (see below)

SCENARIO B: Urgent Hotfix

1. Create hotfix/critical-issue branch from main
2. Fix issue in main's dev environment
3. MANUAL: Create Pull Request → main
4. MANUAL: Emergency 2-person approval
5. AUTOMATED: Same as Release workflow above
6. Auto-merge back to develop
```

### Phase 5: Rollback (If Needed)
```
1. Incident detected in production
2. MANUAL: Identify previous stable version (e.g., v1.1.0)
3. MANUAL: Checkout previous tag from GitHub
4. AUTOMATED:
   - Export solution from tag
   - Backup current production
   - Deploy previous version to prod
   - Verify deployment success
   - Run smoke tests
5. Time to Recover: <15 minutes
6. MANUAL: Incident post-mortem
7. ROOT CAUSE FIX: Create bugfix/* from develop
```

---

## GitHub Actions Workflow Checklist

### Workflow 1: PR Validation (on feature/* → develop)
```
✅ Trigger: Pull Request created to develop
✅ Steps:
  1. Export unmanaged solution from dev environment
  2. Unpack XML to source files
  3. Run solution checker (linting)
  4. Run unit tests (if configured)
  5. Generate test report
  6. Comment results on PR
  7. Pass/Fail block merge
```

### Workflow 2: Deploy to Test (on merge to develop)
```
✅ Trigger: Merge commit to develop
✅ Steps:
  1. Export unmanaged solution from dev
  2. Pack into managed solution
  3. Import to TEST environment
  4. Verify import success
  5. Run smoke tests
  6. Generate deployment report
  7. Send team notification
```

### Workflow 3: Release to Production (on merge to main)
```
✅ Trigger: Merge commit to main (requires approvals)
✅ Steps:
  1. Create version tag (v1.2.3)
  2. Export unmanaged solution
  3. Generate managed solution
  4. Backup PRODUCTION environment
  5. Import managed solution to PRODUCTION
  6. Verify import success
  7. Run smoke tests
  8. Generate deployment report
  9. Send team notification
  10. Create GitHub Release notes
```

### Workflow 4: Rollback (manual trigger)
```
✅ Trigger: Manual dispatch from Actions
✅ Inputs:
  - Previous version tag (v1.1.0)
✅ Steps:
  1. Checkout previous tag
  2. Export solution
  3. Backup current production
  4. Import previous version
  5. Verify success
  6. Generate rollback report
  7. Create incident issue
```

---

## Service Principal Configuration

### Azure AD Service Principal Setup
```
Required Information:
├── Tenant ID: [Your AD Tenant ID]
├── Client ID (App ID): [Service Principal Application ID]
├── Client Secret: [Generated Secret]
└── MFA: Enabled (recommended)

Permission Scopes Required:
├── Power Platform: https://service.powerapps.com/.default
├── Dataverse: user_impersonation (delegated)
└── Dynamics CRM: user_impersonation (delegated)
```

### GitHub Secrets Configuration
```
TENANT_ID = [Azure AD Tenant ID]
CLIENT_ID = [Service Principal Client ID]
CLIENT_SECRET = [Service Principal Secret - MASKED]
ENVIRONMENT_URL = https://[org].crm.dynamics.com
SERVICE_PRINCIPAL_USER_ID = [Service Principal User ID]
```

### Access Requirements
```
Power Platform:
├── Dev Environment: Environment Admin
├── Test Environment: Environment Admin
├── Pre-Prod Environment: Environment Admin
└── Production Environment: Environment Admin

Dataverse:
├── Export Solution: Solution Admin
├── Import Solution: Solution Admin
└── Deployment Admin

Azure DevOps (if used):
└── Project: Contributor
```

---

## Approval Gates & Reviews

### Feature Branch → Develop (Code Review)
```
Approval Requirements:
├── ✅ PR Description: Clear explanation of changes
├── ✅ Test Results: Passing solution checker
├── ✅ Team Review: Minimum 1 approval
└── ✅ No Conflicts: Clean merge path

Review Checklist:
├── [ ] Solution components documented
├── [ ] No breaking changes
├── [ ] Follows naming conventions
├── [ ] Unit tests passing
└── [ ] Solution checker clean
```

### Release Branch → Main (Production Release)
```
Approval Requirements:
├── ✅ Release Manager Approval: 1st person
├── ✅ Technical Lead Approval: 2nd person (must be different)
├── ✅ Test Results: QA verified in test environment
├── ✅ Version Number: Incremented properly
└── ✅ Release Notes: Documented

Release Verification:
├── [ ] All PRs merged and tested
├── [ ] Version number updated
├── [ ] Release notes written
├── [ ] Rollback plan documented
├── [ ] Stakeholders notified
└── [ ] Change window confirmed
```

---

## Monitoring & Alerts

### Key Metrics to Track
```
Deployment Success Rate:
├── Target: >95%
├── Track: Failed deployments per month
└── Alert: If <95% two consecutive months

Mean Time to Recovery (MTTR):
├── Target: <15 minutes
├── Track: Time from detection to rollback complete
└── Alert: If >30 minutes

Lead Time for Changes:
├── Track: Days from feature branch create to production
├── Benchmark: Industry average 7-14 days
└── Improvement: Target <7 days

Change Failure Rate:
├── Target: <15%
├── Track: Percentage of deployments causing incidents
└── Alert: If >20%
```

### GitHub Actions Notifications
```
Configure in Settings → Notifications:
├── ✅ Workflow runs completed
├── ✅ Pull request approvals
├── ✅ Release created
└── ✅ Deployment failures

Optional Integrations:
├── Slack: #deployments channel
├── Teams: Power Platform channel
├── Email: Team lead + on-call
└── PagerDuty: Critical incidents
```

---

## Developer Onboarding Checklist

### Week 1: Setup
```
☐ Create personal Power Platform developer environment
☐ Receive GitHub repository access
☐ Clone repository (git clone ssh://...)
☐ Review Git Flow branching guide
☐ Review ALM workflow documentation
☐ Set up Power Platform Git Integration in dev environment
```

### Week 2: First Contribution
```
☐ Create feature/your-feature branch
☐ Create unmanaged solution in dev environment
☐ Enable Git integration for solution
☐ Make first change and commit
☐ Push to GitHub (git push)
☐ Create Pull Request to develop
☐ Code review session with senior dev
☐ Merge approved PR
☐ Watch automated tests run
☐ See deployment to test environment
```

### Week 3+: Ongoing
```
☐ Regular feature development via feature branches
☐ Pull request code reviews with peers
☐ Participation in test environment QA
☐ Understanding of release process
☐ Familiarity with rollback procedures
☐ Mentorship of new team members
```

---

## Common Issues & Solutions

### Issue: PR Validation Fails
```
Symptom: "Solution checker found 16 issues"
Solution:
1. Run solution checker locally in dev environment
2. Fix identified issues (usually naming, dependencies)
3. Commit fixes
4. PR auto-reruns validation
5. If persistent, discuss with tech lead
```

### Issue: Deployment to Test Fails
```
Symptom: "Import failed: Missing dependency"
Solution:
1. Verify all dependent solutions imported in test
2. Check version compatibility
3. Review solution layers in target environment
4. If dependency missing, import base solution first
5. Retry deployment from release history if available
```

### Issue: Merge Conflict in Git
```
Symptom: "Cannot merge feature/task1 (conflicts with develop)"
Solution:
1. git fetch origin develop
2. git rebase origin/develop
3. Resolve conflicts in VS Code
4. Commit conflict resolution
5. Force push to feature branch (git push -f)
6. PR automatically updates
```

### Issue: Need Hotfix to Production
```
Steps:
1. git fetch origin main
2. git checkout -b hotfix/issue-name origin/main
3. Make fix in dev environment
4. Commit and push hotfix branch
5. Create PR to main (mark as hotfix)
6. Get 2-person emergency approval
7. Merge to main (triggers auto-deploy)
8. Auto-merge back to develop
```

---

## Performance Tips

### Local Development
```
✅ Use Power Apps Portals (cloud-based editor)
  Faster than desktop without network latency

✅ Enable Git auto-sync
  Real-time sync with GitHub as you develop

✅ Test solution size
  Monitor solution.xml file size
  Alert if >50MB (may indicate need for multi-solution)

✅ Regular commits
  Small commits (1-2 components per commit)
  Easier to trace issues later
```

### CI/CD Optimization
```
✅ Parallel workflow jobs
  Run checker, tests, unit tests in parallel

✅ Cache frequently-used artifacts
  Reduce solution-packaging time

✅ Conditional step execution
  Run resource-intensive tasks only when needed

✅ Monitor workflow duration
  Alert if deployment time increases >20%
```

---

## Compliance & Audit Trail

### What Gets Audited
```
Every Deployment:
├── Who: Service Principal + Approver(s)
├── What: Solution version number
├── When: Timestamp in GitHub Actions log
├── Where: Which environment deployed to
├── Why: Pull request description + comments
└── How: GitHub Actions workflow used

Audit Location:
├── GitHub: Repository commit history + releases
├── Power Platform: Import/export history
├── Azure AD: Service Principal activity logs
└── GitHub Actions: Workflow run logs (90 days)
```

### Retention Policy
```
GitHub Artifacts: Keep indefinitely (per compliance)
Workflow Logs: 90 days (GitHub default)
Solution Backups: 1 year (Pipelines host)
Access Logs: 1 year (Azure AD)
```

---

## FAQ

**Q: Can a developer work on multiple features simultaneously?**  
A: Yes, but use separate feature branches. Git Flow supports multiple feature branches from develop.

**Q: What if production deployment fails?**  
A: Automatic rollback to previous version within 15 minutes. Manual incident post-mortem required.

**Q: Who has access to approve production releases?**  
A: Release Manager + Technical Lead (2-person minimum, must be different people).

**Q: Can I bypass the test environment?**  
A: No. Power Platform Pipelines prevents skipping stages. All deployments must follow the pipeline.

**Q: How do I revert a change already in production?**  
A: Use rollback workflow to redeploy previous version tag. Typically <15 min recovery.

**Q: What's the maximum solution size?**  
A: 95MB per Microsoft. If approaching, evaluate multi-solution strategy.

**Q: Can I deploy unmanaged solutions to production?**  
A: No. Only managed solutions deployable to production. This is a safety feature.

**Q: How do I handle urgent security patches?**  
A: Create hotfix/* branch from main, fix, get emergency approvals, deploy directly to production.

---

## Key Contacts & Resources

| Role | Responsibility |
|------|-----------------|
| **Release Manager** | Approve production releases |
| **Technical Lead** | Code review + conflict resolution |
| **DevOps Engineer** | GitHub Actions maintenance |
| **Environment Admin** | Power Platform environment provisioning |
| **Solution Owner** | Design decisions, architecture |

### External Resources
- Microsoft Learn: https://learn.microsoft.com/power-platform/alm
- GitHub Flow: https://guides.github.com/introduction/flow/
- Power Platform CLI: https://docs.microsoft.com/power-platform/developer/cli
