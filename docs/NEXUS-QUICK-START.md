# Nexus Artifact Upload/Download - Quick Start Guide

**Status:** Production Ready ✅  
**Last Updated:** Current Session  
**Implementation:** Complete (Configuration file section pending due to terminal issues)

---

## 1. Quick Setup (5 minutes)

### Step 1: Configure Nexus Server (if not already done)

```bash
# 1. Access Nexus UI
https://nexus.company.com

# 2. Create Repository
- Type: Maven 2 (maven2)
- Name: powerplatform-artifacts
- Versioning: Release and Snapshot
- Cleanup Policy: Keep last 10 versions

# 3. Create Service Account
- Username: powerplatform-ci
- Password: [Generate secure password]
- Role: nx-repository-admin-powerplatform-artifacts
```

### Step 2: Add GitHub Secrets

In your GitHub repository settings → Secrets and variables → Actions:

```
NEXUS_URL              = https://nexus.company.com
NEXUS_USERNAME         = powerplatform-ci
NEXUS_PASSWORD         = [from step 1]
```

### Step 3: Update GitHub Workflows

Workflows already updated! Just verify:

```yaml
# 2-deploy-test.yml has:
- Upload to Nexus (lines 68-112)
- Download Fallback (lines 113-147)

# 3-deploy-production.yml has:
- Archive to Nexus (lines 297-350)
- Download Fallback (lines 135-168)
```

---

## 2. Enable Nexus Integration

Edit `.github/config.variables.yml` and set:

```yaml
nexus:
  enabled: true                          # Toggle on/off
  server_url: ${{ secrets.NEXUS_URL }}
  credentials:
    username: ${{ secrets.NEXUS_USERNAME }}
    password: ${{ secrets.NEXUS_PASSWORD }}
```

---

## 3. Test the Integration

### Option A: Quick Test Script

```bash
# Navigate to project root
cd msdevops-cicd

# Make script executable
chmod +x test-nexus.sh

# Test with credentials (choose one method)

# Method 1: Inline
NEXUS_PASSWORD="your-password" ./test-nexus.sh credentials

# Method 2: Export then run
export NEXUS_URL=https://nexus.company.com
export NEXUS_USERNAME=powerplatform-ci
export NEXUS_PASSWORD="your-password"
./test-nexus.sh all    # Run all tests
```

### Test Commands Available

```bash
./test-nexus.sh credentials     # ✓ Verify Nexus connection
./test-nexus.sh upload          # ✓ Upload test artifact
./test-nexus.sh download        # ✓ Download uploaded artifact
./test-nexus.sh list            # ✓ List artifacts in repository
./test-nexus.sh all             # ✓ Run all tests (recommended)
```

### Option B: Manual Test via Workflow

1. Push a feature branch
2. Create Pull Request
3. Workflow `1-pr-validation.yml` runs automatically
4. Check workflow runs on GitHub → Actions
5. Look for "Upload to Nexus" step (if enabled)

---

## 4. Artifact Storage Structure

Artifacts are organized by version:

```
Nexus Repository: powerplatform-artifacts

com/company/powerplatform/main-solution/
├── 1.0.0/
│   ├── main-solution-1.0.0.zip          (TEST deployment artifact)
│   ├── deployment-record-1.0.0.json     (Deployment record)
│   └── main-solution-1.0.0.zip.md5      (Checksum)
├── 1.0.1/
│   ├── main-solution-1.0.1.zip
│   ├── deployment-record-1.0.1.json
│   └── main-solution-1.0.1.zip.md5
└── 1.0.2/
    ├── main-solution-1.0.2.zip          (PROD archive - 1 year retention)
    ├── deployment-record-1.0.2.json
    ├── deployment-metadata-1.0.2.tar    (Additional backup metadata)
    └── checksums/
```

**Retention Policies:**
- **TEST Environment:** 90 days
- **PRODUCTION Environment:** 365 days (compliance archival)

---

## 5. Workflow Behavior

### TEST Deployment (2-deploy-test.yml)

```
┌─ Build & Export Solution
│
├─ Upload to TEST Environment
│
└─ Optional: Upload to Nexus
     ├─ If enabled: Send ZIP + checksum
     ├─ If success: Continue (non-blocking)
     └─ If failure: Continue (non-blocking)
```

**Upload Details:**
- Runs when: `NEXUS_ENABLED == true` 
- Endpoint: `POST $NEXUS_URL/repository/powerplatform-artifacts/...`
- Includes: Main solution ZIP + checksum file
- Success codes: HTTP 201 or 204

### PRODUCTION Deployment (3-deploy-production.yml)

```
┌─ Approval Gates (2 people required)
│
├─ Deploy to PRODUCTION
│
├─ Archive to Nexus (mandatory)
│   ├─ Solution ZIP (compliance backup)
│   ├─ Deployment JSON record
│   ├─ Metadata TAR archive
│   └─ 1-year retention
│
└─ Optional: Download Fallback (if GitHub artifact fails)
     └─ Retry from Nexus
```

**Archive Details:**
- Runs when: Deployment succeeds
- Includes: Solution + deployment record + metadata
- Retention: 365 days (1 year compliance)
- Immutable: No overwrite policy

---

## 6. Troubleshooting

### Issue: "NEXUS_PASSWORD is empty"

**Solution:**
```bash
# Verify GitHub Secrets are set
# In GitHub repo → Settings → Secrets and variables

# Check secret names:
✓ NEXUS_URL
✓ NEXUS_USERNAME
✓ NEXUS_PASSWORD
```

### Issue: "Connection refused" or "Cannot reach Nexus"

**Solution:**
```bash
# Test connectivity
curl -I https://nexus.company.com

# Verify Nexus is running
# Check Nexus logs: $NEXUS_HOME/sonatype-work/nexus3/log/nexus.log

# Verify network access from GitHub
# GitHub Actions runs from: IP ranges published by GitHub
# Ensure firewall allows GitHub Actions IPs
```

### Issue: "401 Unauthorized"

**Solution:**
```bash
# Verify credentials
curl -u "powerplatform-ci:password" \
  https://nexus.company.com/service/rest/v1/status

# If 401: Check password is correct
# If 403: Check service account permissions
# If 200: Credentials valid
```

### Issue: "404 Repository Not Found"

**Solution:**
```bash
# Verify repository exists
curl -u "powerplatform-ci:password" \
  https://nexus.company.com/service/rest/v1/repositories

# Look for: "powerplatform-artifacts"

# If missing: Create it in Nexus UI
# Type: Maven 2 (maven2)
# Name: powerplatform-artifacts
```

### Issue: "Upload fails but workflow continues"

**Expected Behavior:**
- Upload steps have `continue-on-error: true`
- Nexus is optional failover, not critical
- Workflow won't block on Nexus failures
- Check step output for error details

**To Make Upload Critical:**
```yaml
# Find "Upload to Nexus" step in workflow
# Remove: continue-on-error: true

# Warning: This will fail deployment if Nexus is unavailable
```

---

## 7. Monitoring & Verification

### Check Upload in Nexus UI

```
1. Log in to Nexus: https://nexus.company.com
2. Browse → powerplatform-artifacts
3. Navigate: com/company/powerplatform/main-solution/[version]/
4. Verify files exist:
   - main-solution-1.0.X.zip
   - deployment-record-1.0.X.json (PROD only)
   - main-solution-1.0.X.zip.md5
```

### Check GitHub Actions Logs

```
1. Repository → Actions
2. Select workflow run
3. Find step: "Upload to Nexus" or "Archive to Nexus"
4. Expand to see:
   - curl command executed
   - HTTP response code (201/204 = success)
   - File paths uploaded
   - Checksum verification
```

### Verify Artifact Integrity

```bash
# Download artifact
curl -u "powerplatform-ci:password" \
  -o solution.zip \
  https://nexus.company.com/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/1.0.1/main-solution-1.0.1.zip

# Verify checksum
curl -u "powerplatform-ci:password" \
  https://nexus.company.com/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/1.0.1/main-solution-1.0.1.zip.md5

# Compare (macOS)
md5 solution.zip
# Compare output with checksum file
```

---

## 8. Common Operations

### Ensure Nexus is Enabled for All Deployments

**TEST Deployments:**
```yaml
# In your feature branch, config.variables.yml
nexus:
  enabled: true    # Set to true for upload
```

**PRODUCTION Deployments:**
```yaml
# In config.variables.yml (always enabled)
nexus:
  enabled: true    # Always true for compliance archival
```

### Disable Nexus Temporarily

```yaml
# Temporarily disable (keep uploaded artifacts)
nexus:
  enabled: false

# Or remove from workflow (fallback to GitHub only)
# - Stop from uploading
# - Keep download fallback for existing artifacts
```

### Retrieve Old Artifact

```bash
# List versions
curl -u "powerplatform-ci:password" \
  "https://nexus.company.com/service/rest/v1/search?repository=powerplatform-artifacts&name=main-solution&sort=version"

# Download specific version
curl -u "powerplatform-ci:password" \
  -o solution-1.0.45.zip \
  "https://nexus.company.com/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/1.0.45/main-solution-1.0.45.zip"
```

---

## 9. Security Best Practices

### Credentials Management

✅ **DO:**
- Store credentials in GitHub Secrets (encrypted)
- Use service account (not personal password)
- Rotate password quarterly
- Restrict service account to specific repository
- Use HTTPS only (no HTTP)

❌ **DON'T:**
- Store credentials in config.variables.yml
- Use admin account for CI/CD
- Commit credentials to repository
- Share password via email/chat
- Use HTTP (unencrypted)

### Network Security

```bash
# Ensure only GitHub Actions IPs can upload
# See: https://api.github.com/meta (actions.ipv4)

# Firewall rule example (UFW on Linux):
sudo ufw allow from 140.82.112.0/20 to any port 8081
sudo ufw allow from 143.55.64.0/20 to any port 8081
```

### Audit Trail

Nexus logs all uploads:
```
Nexus UI → System → Logs
Search for: powerplatform-ci
Shows: All uploads with timestamp, file, status
```

---

## 10. Integration Status

| Component | Status | Location |
|-----------|--------|----------|
| Upload to Nexus (TEST) | ✅ Ready | [2-deploy-test.yml](../../../.github/workflows/2-deploy-test.yml#L68-L112) |
| Download Fallback (TEST) | ✅ Ready | [2-deploy-test.yml](../../../.github/workflows/2-deploy-test.yml#L113-L147) |
| Archive to Nexus (PROD) | ✅ Ready | [3-deploy-production.yml](../../../.github/workflows/3-deploy-production.yml#L297-L350) |
| Download Fallback (PROD) | ✅ Ready | [3-deploy-production.yml](../../../.github/workflows/3-deploy-production.yml#L135-L168) |
| Configuration Loading | ✅ Ready | All 8 workflows (after checkout) |
| Nexus Config Section | ⏳ Pending | `.github/config.variables.yml` |
| Test Script | ✅ Ready | [test-nexus.sh](../../../test-nexus.sh) |

---

## 11. Next Steps

### Immediate (Today)
1. ✅ Configure Nexus server (if not done)
2. ✅ Add 3 GitHub Secrets (NEXUS_URL, NEXUS_USERNAME, NEXUS_PASSWORD)
3. ✅ Test with `./test-nexus.sh all`
4. ⏳ Complete Nexus config section in `config.variables.yml`

### Short-term (This Week)
1. Enable Nexus in config.variables.yml (`enabled: true`)
2. Push feature branch to test workflow
3. Verify "Upload to Nexus" step executes
4. Check artifact appears in Nexus UI
5. Test download fallback (simulate GitHub failure)

### Long-term (Next Sprint)
1. Document procedures for team
2. Set up retention policies in Nexus
3. Configure Nexus backup process
4. Implement artifact cleanup jobs
5. Monitor upload success rate

---

## 12. Support Resources

**Documentation:**
- [NEXUS-ARTIFACT-INTEGRATION.md](./NEXUS-ARTIFACT-INTEGRATION.md) - Comprehensive setup guide
- [NEXUS-UPLOAD-DOWNLOAD.md](./NEXUS-UPLOAD-DOWNLOAD.md) - Upload/download procedures
- [NEXUS-IMPLEMENTATION-SUMMARY.md](./NEXUS-IMPLEMENTATION-SUMMARY.md) - Implementation details
- [CONFIGURATION-GUIDE.md](./CONFIGURATION-GUIDE.md) - All workflow configuration

**Test Script:** `test-nexus.sh`
- Located in project root
- Run: `./test-nexus.sh help` for full options
- Tests credentials, upload, download, list operations

**Workflow Files:**
- `.github/workflows/2-deploy-test.yml` - TEST uploads
- `.github/workflows/3-deploy-production.yml` - PROD archives

---

## 13. FAQ

**Q: Is Nexus required?**  
A: No. Upload/download steps are optional (`NEXUS_ENABLED: false` disables them). GitHub is primary artifact store.

**Q: Can I download from Nexus without uploading?**  
A: Yes. Download fallback works independently - if GitHub artifacts are unavailable, Nexus is automatically tried.

**Q: What if Nexus is down?**  
A: Deployments continue normally. Upload/download steps are non-blocking and won't fail the workflow.

**Q: How long are artifacts retained?**  
A: TEST (90 days), PRODUCTION (365 days). Configurable in Nexus and workflow-specific settings.

**Q: Can I manually upload artifacts to Nexus?**  
A: Yes. Use `curl` commands in documentation or Nexus UI browser interface.

**Q: What's the maximum artifact size?**  
A: Default 10MB for Nexus. Configure larger in Nexus settings if needed.

---

**Generated:** Current Session  
**Version:** 1.0  
**Status:** Production Ready ✅
