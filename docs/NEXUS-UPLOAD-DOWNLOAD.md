# Nexus Artifact Upload & Download Configuration

## Overview

This document defines the Nexus artifact upload and download configuration integrated into your CI/CD workflows.

---

## Nexus Configuration Variables

### Server Setup

```yaml
nexus:
  enabled: false
  server_url: "https://nexus.company.com"
  repository:
    name: "powerplatform-artifacts"
    type: "maven2"
```

### Authentication (GitHub Secrets Required)

```
NEXUS_URL              = https://nexus.company.com
NEXUS_USERNAME         = powerplatform-ci
NEXUS_PASSWORD         = [generated-password]
```

### Upload Configuration

```yaml
upload:
  enabled: true
  on_test_deployment: true
  on_production_deployment: true
  paths:
    test:
      - "build/*/solution-*-managed.zip"
      - "build/*/checksums.sha256"
    production:
      - "deploy/artifacts/solution-*-managed.zip"
      - "deployment-record.json"
      - "backup-info/*"
```

### Download Configuration

```yaml
download:
  enabled: false
  fallback_to_github: true
  verify_checksum: true
```

### Retention Policies

```yaml
retention:
  test_artifacts_days: 90
  prod_artifacts_days: 365
  max_versions_to_keep: 100
```

---

## Workflow Integration

### 2-deploy-test.yml - Upload Steps

**After building solution, add upload:**

```yaml
- name: Upload to Nexus (Test Environment)
  if: ${{ env.NEXUS_ENABLED == 'true' && env.NEXUS_UPLOAD_ENABLED == 'true' }}
  env:
    NEXUS_URL: ${{ secrets.NEXUS_URL }}
    NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
    NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
    VERSION: ${{ steps.version.outputs.version }}
    NEXUS_REPO: powerplatform-artifacts
  run: |
    set -e
    
    ARTIFACT_FILE="build/${VERSION}/solution-${VERSION}-managed.zip"
    CHECKSUM_FILE="build/${VERSION}/checksums.sha256"
    
    if [ ! -f "$ARTIFACT_FILE" ]; then
      echo "⚠️ Artifact not found: $ARTIFACT_FILE"
      exit 1
    fi
    
    echo "📦 Uploading to Nexus..."
    echo "  File: $ARTIFACT_FILE"
    echo "  Repository: $NEXUS_REPO"
    echo "  Version: $VERSION"
    
    # Upload solution
    curl -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
      -F "file=@${ARTIFACT_FILE}" \
      "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/"
    
    # Upload checksum
    if [ -f "$CHECKSUM_FILE" ]; then
      curl -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        -F "file=@${CHECKSUM_FILE}" \
        "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/"
    fi
    
    echo "✅ Upload complete"
```

### 3-deploy-production.yml - Upload Steps

**After production deployment, add archive:**

```yaml
- name: Archive to Nexus (Production Environment)
  if: ${{ env.NEXUS_ENABLED == 'true' && env.NEXUS_PROD_UPLOAD_ENABLED == 'true' }}
  env:
    NEXUS_URL: ${{ secrets.NEXUS_URL }}
    NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
    NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
    VERSION: ${{ needs.pre-deployment-checks.outputs.release-version }}
    NEXUS_REPO: powerplatform-artifacts
  run: |
    set -e
    
    ARTIFACT_FILE="deploy/artifacts/solution-${VERSION}-managed.zip"
    DEPLOYMENT_RECORD="deployment-record.json"
    
    echo "📦 Archiving production deployment to Nexus..."
    echo "  Version: $VERSION"
    echo "  Environment: Production"
    
    # Upload managed solution
    if [ -f "$ARTIFACT_FILE" ]; then
      curl -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        -F "file=@${ARTIFACT_FILE}" \
        "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/"
    fi
    
    # Upload deployment record
    if [ -f "$DEPLOYMENT_RECORD" ]; then
      curl -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        -F "file=@${DEPLOYMENT_RECORD}" \
        "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/metadata/"
    fi
    
    echo "✅ Archive complete - Production artifacts preserved for 1 year"
```

### 2-deploy-test.yml - Download Steps (Optional)

**Alternative: Download from Nexus instead of GitHub:**

```yaml
- name: Download from Nexus (Alternative)
  if: ${{ env.NEXUS_DOWNLOAD_ENABLED == 'true' && failure() }}
  continue-on-error: true
  env:
    NEXUS_URL: ${{ secrets.NEXUS_URL }}
    NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
    NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
    VERSION: ${{ needs.build-solution.outputs.solution-version }}
    NEXUS_REPO: powerplatform-artifacts
  run: |
    echo "⬇️ Downloading artifacts from Nexus (fallback)..."
    
    ARTIFACT="solution-${VERSION}-managed.zip"
    
    curl -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
      -o "$ARTIFACT" \
      "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/$ARTIFACT"
    
    if [ -f "$ARTIFACT" ]; then
      echo "✅ Downloaded from Nexus"
      mkdir -p deploy/artifacts
      mv "$ARTIFACT" deploy/artifacts/
    else
      echo "❌ Nexus download failed"
      exit 1
    fi
```

---

## REST API Endpoints

### Search for Artifacts

```bash
curl -u "powerplatform-ci:password" \
  "https://nexus.company.com/service/rest/v1/search?repository=powerplatform-artifacts&name=main-solution"
```

### List Component Versions

```bash
curl -u "powerplatform-ci:password" \
  "https://nexus.company.com/service/rest/v1/components?repository=powerplatform-artifacts"
```

### Download Artifact

```bash
curl -u "powerplatform-ci:password" \
  -O "https://nexus.company.com/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/1.0.45/solution-1.0.45-managed.zip"
```

### Upload Artifact

```bash
curl -u "powerplatform-ci:password" \
  -F "file=@solution-1.0.45-managed.zip" \
  "https://nexus.company.com/repository/powerplatform-artifacts/com/company/powerplatform/main-solution/1.0.45/"
```

---

## GitHub Secrets Required

Add these to your GitHub repository:

| Secret | Value | Example |
|--------|-------|---------|
| `NEXUS_URL` | Nexus server URL | `https://nexus.company.com` |
| `NEXUS_USERNAME` | CI service account | `powerplatform-ci` |
| `NEXUS_PASSWORD` | Service account password | `[strong-password]` |

---

## Enabling Nexus Integration

### Step 1: Update Workflows

Add to both `2-deploy-test.yml` and `3-deploy-production.yml`:

```yaml
- name: Load Nexus Configuration
  uses: actions/github-script@v7
  with:
    script: |
      core.exportVariable('NEXUS_ENABLED', 'true');
      core.exportVariable('NEXUS_UPLOAD_ENABLED', 'true');
      core.exportVariable('NEXUS_PROD_UPLOAD_ENABLED', 'true');
```

### Step 2: Add GitHub Secrets

1. Go to repository Settings
2. Secrets and variables → Actions
3. Add `NEXUS_URL`, `NEXUS_USERNAME`, `NEXUS_PASSWORD`

### Step 3: Deploy Nexus Server

- Set up Nexus instance
- Create repository `powerplatform-artifacts`
- Create CI service account

### Step 4: Test Upload

```bash
# Run workflow
gh workflow run 2-deploy-test.yml

# Check Nexus UI
https://nexus.company.com/repository/powerplatform-artifacts/
```

---

## Artifact Lifecycle

### Test Artifacts (90 days)

```
Deploy to TEST ➜ Upload to Nexus ➜ Store 90 days ➜ Auto-delete
```

### Production Artifacts (365 days)

```
Deploy to PROD ➜ Archive to Nexus ➜ Store 1 year ➜ Retained for audit
```

### Backup Records (365 days)

```
Pre-deploy backup ➜ Store in Nexus ➜ Available for 1 year ➜ Rollback reference
```

---

## Monitoring Upload Status

### Check Nexus Browser

```
Nexus UI → Browse → powerplatform-artifacts
→ com/company/powerplatform/main-solution/
→ [version folders]
```

### Check Workflow Logs

```
GitHub UI → Actions → [workflow run]
→ Upload to Nexus step
→ View curl response
```

### API Health Check

```bash
curl -u "powerplatform-ci:password" \
  "https://nexus.company.com/service/rest/api/v1/status"

# Response: {"licenseInstalled":true,"edition":"...","version":"..."}
```

---

## Troubleshooting

### 401 Unauthorized

**Problem:** Credentials invalid  
**Solution:**
- Verify secrets in GitHub
- Test credentials locally
- Regenerate password in Nexus

### 404 Repository Not Found

**Problem:** Repository doesn't exist  
**Solution:**
- Create repository in Nexus
- Verify repository name matches config
- Check permissions

### Connection Timeout

**Problem:** Network issue  
**Solution:**
- Check Nexus is running
- Verify firewall rules
- Test from GitHub runner

### Disk Full

**Problem:** No space on Nexus server  
**Solution:**
- Enable cleanup policies
- Delete old artifacts
- Increase storage
