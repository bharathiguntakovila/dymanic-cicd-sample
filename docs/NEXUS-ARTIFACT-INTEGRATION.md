# Nexus Artifact Repository Integration Guide

## Overview

This guide shows how to integrate Sonatype Nexus as your centralized artifact repository for Power Platform CI/CD automation. Nexus provides long-term artifact storage, versioning, and management alongside GitHub Actions.

---

## Table of Contents

1. [Why Nexus?](#why-nexus)
2. [Prerequisites](#prerequisites)
3. [Nexus Setup](#nexus-setup)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Enable Nexus in Workflows](#enable-nexus-in-workflows)
6. [Artifact Storage Strategy](#artifact-storage-strategy)
7. [Accessing Archived Artifacts](#accessing-archived-artifacts)
8. [Maintenance & Cleanup](#maintenance--cleanup)
9. [Troubleshooting](#troubleshooting)

---

## Why Nexus?

**GitHub Artifacts:**
- ✅ Free with Actions
- ❌ Limited retention (default 90 days, max 365 days)
- ❌ Shared quota across all repositories
- ❌ Not designed for long-term archival

**Nexus Repository:**
- ✅ Centralized artifact management
- ✅ Unlimited retention (with disk space)
- ✅ Advanced versioning and promotion workflows
- ✅ Fine-grained access control
- ✅ Build metadata tracking
- ✅ Compliance & audit trails
- ✅ Artifact search and discovery
- ✅ Bandwidth management

---

## Prerequisites

### Nexus Server Setup

1. **Nexus Installation**
   - Deployed on-premises or cloud VM
   - Accessible from GitHub Actions runner (firewall rules configured)
   - Version 3.0+ recommended

2. **Maven2 Repository**
   - Create hosted repository: `powerplatform-artifacts`
   - Repository Type: `maven2`
   - Layout Policy: `Strict`
   - Versioning Policy: `Release`

3. **Service Account**
   - Create Nexus user: `powerplatform-ci`
   - Grant roles: `Viewer`, `Deployer`, `Repository Admin`
   - Generate credentials

---

## Nexus Setup

### Step 1: Create Nexus Repository

```bash
# Login to Nexus UI
# Navigate to: Administration → Repositories → Create Repository

Name: powerplatform-artifacts
Type: maven2 (Hosted)
Cleanup Policy Predicates:
  - Is released: true
  - Last downloaded: 30 days ago
```

### Step 2: Configure Cleanup

**Keep Production Artifacts (1 year minimum):**
```
Cleanup Policy: Keep releases
Retention Days: 365
```

**Clean Old Versions (Keep last 20):**
```
Max Versions to Keep: 20
```

### Step 3: Configure Security

```bash
# Create CI User in Nexus
Username: powerplatform-ci
Password: [Generate Strong Password]
Roles: 
  - nx-repository-view-maven2-powerplatform-artifacts-*
  - nx-repository-admin-maven2-powerplatform-artifacts-*
```

---

## GitHub Secrets Configuration

In your GitHub Repository Settings → Secrets and variables → Actions, add:

```
NEXUS_URL              = https://nexus.company.com
NEXUS_REPOSITORY       = powerplatform-artifacts
NEXUS_USERNAME         = powerplatform-ci
NEXUS_PASSWORD         = [generated-password]
NEXUS_ENABLED          = true (or false to disable)
```

### Security Best Practices

- ✅ Use strong passwords (min 16 chars, mix of upper/lower/numbers/symbols)
- ✅ Rotate credentials quarterly
- ✅ Use separate CI user account (not personal account)
- ✅ Grant minimal required permissions
- ✅ Enable IP whitelist in Nexus firewall rules

---

## Enable Nexus in Workflows

### Option 1: Update Configuration File

Edit `.github/config.variables.yml`:

```yaml
nexus:
  enabled: true                     # Change to true
  server_url: "https://nexus.company.com"
  upload:
    enabled: true
    on_test_deployment: true        # Upload TEST solutions
    on_production_deployment: true  # Archive PROD solutions
  retention:
    keep_days: 365
    max_retention_count: 100
```

### Option 2: Update Workflows Directly

Load Nexus configuration in workflow:

```yaml
- name: Load Configuration
  uses: actions/github-script@v7
  with:
    script: |
      const yaml = require('js-yaml');
      const fs = require('fs');
      const config = yaml.load(fs.readFileSync('.github/config.variables.yml', 'utf8'));
      core.exportVariable('NEXUS_ENABLED', config.nexus.enabled);
      core.exportVariable('NEXUS_REPO', config.nexus.repository.name);
```

---

## Artifact Storage Strategy

### What Gets Uploaded to Nexus?

| Artifact | When | Retention | Purpose |
|----------|------|-----------|---------|
| **Test Managed Solutions** | After TEST deployment | 90 days | QA reference |
| **Production Solutions** | After PROD deployment | 365 days | Compliance audit trail |
| **Deployment Records** | After PROD deployment | 365 days | Deployment history |
| **Pre-Deploy Backups** | Before PROD import | 365 days | Rollback reference |
| **Health Check Reports** | Monthly | 90 days | Performance tracking |
| **Monitoring Reports** | Monthly | 90 days | Trend analysis |

### Artifact Naming Convention

```
powerplatform-{solution-name}-{version}-{environment}.zip

Examples:
- powerplatform-main-solution-1.0.45-test.zip
- powerplatform-main-solution-1.0.45-prod.zip
- powerplatform-main-solution-1.0.45-backup.zip
```

### Directory Structure in Nexus

```
com/
└── company/
    └── powerplatform/
        └── main-solution/
            ├── 1.0.40/
            │   ├── main-solution-1.0.40-test.zip
            │   ├── main-solution-1.0.40-prod.zip
            │   └── main-solution-1.0.40-prod.zip.sha256
            ├── 1.0.41/
            ├── 1.0.42/
            └── 1.0.45/  (current)
```

---

## Accessing Archived Artifacts

### From Nexus UI

1. **Browse Repository**
   - Nexus UI → Browse → powerplatform-artifacts
   - Navigate by version
   - Download or view details

2. **Search**
   - Nexus UI → Search
   - Search by: version, file name, date
   - Filter by component, repository, format

### From Workflows

**Download artifact for inspection:**

```yaml
- name: Download from Nexus
  if: ${{ env.NEXUS_ENABLED == 'true' }}
  run: |
    curl -u "${{ secrets.NEXUS_USERNAME }}:${{ secrets.NEXUS_PASSWORD }}" \
      -o solution.zip \
      "${{ secrets.NEXUS_URL }}/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/${VERSION}/main-solution-${VERSION}-prod.zip"
```

### REST API Access

**Get artifact info:**

```bash
curl -u "powerplatform-ci:password" \
  "https://nexus.company.com/service/rest/v1/search?repository=powerplatform-artifacts&name=main-solution"
```

**Upload artifact:**

```bash
curl -u "powerplatform-ci:password" \
  -F "file=@solution.zip" \
  "https://nexus.company.com/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/1.0.45/"
```

---

## Maintenance & Cleanup

### Weekly Maintenance

**Automatic cleanup in Nexus:**
- Run daily/weekly (Nexus UI → Admin → Cleanup Policies)
- Removes artifacts older than retention period
- Keeps only latest `max_retention_count` versions

### Manual Cleanup

**Delete old versions:**
```bash
# Nexus UI → Browse → powerplatform-artifacts
# Right-click component → Delete
```

**Export retention report:**
```bash
# Nexus UI → Administration → Tasks
# Create task: "Purge Old Artifacts"
# Schedule: Weekly
```

### Monitoring

**Track artifact statistics:**
```bash
# Nexus UI → Administration → System → Statistics
# View: Total artifacts, storage usage, bandwidth

# Current stats:
# - Total items: 50+
# - Total size: ~500 MB
# - Growth rate: ~50 MB/week
```

---

## Troubleshooting

### Issue: "Upload Failed - 401 Unauthorized"

**Solution:**
1. Verify credentials in GitHub Secrets
2. Check Nexus user permissions
3. Confirm credentials are not expired
4. Test manually:
   ```bash
   curl -u "powerplatform-ci:password" \
     "https://nexus.company.com/service/rest/api/v1/status"
   ```

### Issue: "Connection Refused - Nexus Unreachable"

**Solution:**
1. Verify Nexus URL in GitHub Secrets (`NEXUS_URL`)
2. Check network connectivity from GitHub Actions
3. Verify firewall rules allow outbound to Nexus
4. Check Nexus service is running:
   ```bash
   # On Nexus server
   sudo systemctl status nexus
   ```

### Issue: "Insufficient Storage - Disk Full"

**Solution:**
1. Clean old artifacts (see Maintenance section)
2. Delete test artifacts older than 90 days
3. Increase disk space on Nexus server
4. Configure automatic purge:
   ```yaml
   cleanup-policy:
     max-component-age: 30  # days
     release-type: release
   ```

### Issue: "Artifact Upload Timeout"

**Solution:**
1. Increase upload timeout in workflow:
   ```yaml
   timeout-minutes: 60  # Increase from 30
   ```
2. Check Nexus performance during upload
3. Verify network bandwidth
4. Split large artifacts into smaller uploads

### Debugging Steps

**Enable verbose logging:**

```yaml
- name: Upload with Debug
  env:
    DEBUG: true
  run: |
    set -x  # Enable bash debugging
    curl -v -u "..." "https://nexus.company.com/..."
```

**Test connectivity:**

```bash
# From workflow or locally
telnet nexus.company.com 8081
curl -I https://nexus.company.com/
curl -v -u "user:pass" https://nexus.company.com/service/rest/api/v1/status
```

---

## Integration with Workflows

### 2-deploy-test.yml Integration

```yaml
- name: Upload to Nexus (Optional)
  if: ${{ env.NEXUS_ENABLED == 'true' }}
  env:
    NEXUS_URL: ${{ secrets.NEXUS_URL }}
    NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
    NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
  run: |
    VERSION="${{ steps.version.outputs.version }}"
    ARTIFACT="solution-${VERSION}-managed.zip"
    
    echo "📦 Uploading to Nexus..."
    curl -u "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" \
      -F "file=@build/${VERSION}/${ARTIFACT}" \
      "${NEXUS_URL}/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/${VERSION}/"
```

### 3-deploy-production.yml Integration

```yaml
- name: Archive to Nexus
  if: ${{ env.NEXUS_ENABLED == 'true' }}
  uses: actions/github-script@v7
  with:
    script: |
      const fs = require('fs');
      console.log('📦 Archiving to Nexus...');
      // Implementation details in workflow file
```

---

## Next Steps

1. **Install Nexus** - Deploy on infrastructure
2. **Create Repository** - Set up `powerplatform-artifacts`
3. **Add GitHub Secrets** - Configure credentials
4. **Enable in Config** - Set `nexus.enabled: true`
5. **Test Integration** - Run workflow and verify upload
6. **Automate Cleanup** - Schedule retention policies
7. **Monitor Usage** - Track storage and artifacts

---

## Support & Questions

For Nexus-specific questions:
- Sonatype Documentation: https://help.sonatype.com/
- Nexus REST API: https://help.sonatype.com/repomanager3/rest-and-integration-api

For GitHub Actions integration:
- See Configuration Guide: [docs/CONFIGURATION-GUIDE.md](docs/CONFIGURATION-GUIDE.md)
- See Workflow docs: [.github/workflows/](.github/workflows/)
