#!/bin/bash
# Nexus Artifact Upload & Download Test Scripts
# Use these to test Nexus integration before enabling in workflows

set -e

# ============================================================================
# TEST: Upload Artifact to Nexus
# ============================================================================
test_nexus_upload() {
    echo "🧪 Testing Nexus Upload..."
    echo ""
    
    # Configuration
    NEXUS_URL="${NEXUS_URL:-https://nexus.company.com}"
    NEXUS_USERNAME="${NEXUS_USERNAME:-powerplatform-ci}"
    NEXUS_PASSWORD="${NEXUS_PASSWORD}"
    NEXUS_REPO="powerplatform-artifacts"
    VERSION="1.0.test"
    
    # Validate
    if [ -z "$NEXUS_PASSWORD" ]; then
        echo "❌ NEXUS_PASSWORD not set"
        echo "Usage: export NEXUS_PASSWORD=... && $0"
        return 1
    fi
    
    # Create test artifact
    echo "Creating test artifact..."
    ARTIFACT_FILE="test-solution-${VERSION}.zip"
    echo "This is a test artifact" > "$ARTIFACT_FILE"
    
    echo ""
    echo "📤 Uploading to Nexus..."
    echo "  URL: $NEXUS_URL"
    echo "  Repository: $NEXUS_REPO"
    echo "  Version: $VERSION"
    echo "  File: $ARTIFACT_FILE"
    echo ""
    
    # Upload
    RESPONSE=$(curl -s -w "\n%{http_code}" -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        -F "file=@${ARTIFACT_FILE}" \
        "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    echo "Response HTTP Code: $HTTP_CODE"
    echo ""
    
    if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
        echo "✅ Upload successful!"
        echo ""
        echo "📁 Artifact now available at:"
        echo "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/$ARTIFACT_FILE"
        rm -f "$ARTIFACT_FILE"
        return 0
    else
        echo "❌ Upload failed with HTTP $HTTP_CODE"
        echo ""
        echo "Possible issues:"
        echo "  - Check NEXUS_PASSWORD is correct"
        echo "  - Verify service account has permissions"
        echo "  - Ensure repository exists"
        echo "  - Check network connectivity to Nexus"
        rm -f "$ARTIFACT_FILE"
        return 1
    fi
}

# ============================================================================
# TEST: Download Artifact from Nexus
# ============================================================================
test_nexus_download() {
    echo "🧪 Testing Nexus Download..."
    echo ""
    
    # Configuration
    NEXUS_URL="${NEXUS_URL:-https://nexus.company.com}"
    NEXUS_USERNAME="${NEXUS_USERNAME:-powerplatform-ci}"
    NEXUS_PASSWORD="${NEXUS_PASSWORD}"
    NEXUS_REPO="powerplatform-artifacts"
    VERSION="${1:-1.0.test}"  # Use uploaded version or pass as arg
    
    # Validate
    if [ -z "$NEXUS_PASSWORD" ]; then
        echo "❌ NEXUS_PASSWORD not set"
        return 1
    fi
    
    ARTIFACT_FILE="test-solution-${VERSION}.zip"
    
    echo "📥 Downloading from Nexus..."
    echo "  URL: $NEXUS_URL"
    echo "  Repository: $NEXUS_REPO"
    echo "  Version: $VERSION"
    echo "  File: $ARTIFACT_FILE"
    echo ""
    
    # Download
    RESPONSE=$(curl -s -w "\n%{http_code}" -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        -o "$ARTIFACT_FILE" \
        "$NEXUS_URL/repository/$NEXUS_REPO/com/company/powerplatform/main-solution/$VERSION/$ARTIFACT_FILE")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    echo "Response HTTP Code: $HTTP_CODE"
    echo ""
    
    if [ -f "$ARTIFACT_FILE" ] && ([ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]); then
        echo "✅ Download successful!"
        echo "   File size: $(du -h "$ARTIFACT_FILE" | cut -f1)"
        echo "   Content: $(head -c 50 "$ARTIFACT_FILE")"
        rm -f "$ARTIFACT_FILE"
        return 0
    else
        echo "❌ Download failed with HTTP $HTTP_CODE"
        echo ""
        echo "Possible issues:"
        echo "  - Version doesn't exist (try uploading first)"
        echo "  - Check service account permissions"
        echo "  - Verify repository name"
        [ -f "$ARTIFACT_FILE" ] && rm -f "$ARTIFACT_FILE"
        return 1
    fi
}

# ============================================================================
# TEST: List Artifacts in Repository
# ============================================================================
test_nexus_list() {
    echo "🧪 Testing Nexus List Artifacts..."
    echo ""
    
    # Configuration
    NEXUS_URL="${NEXUS_URL:-https://nexus.company.com}"
    NEXUS_USERNAME="${NEXUS_USERNAME:-powerplatform-ci}"
    NEXUS_PASSWORD="${NEXUS_PASSWORD}"
    NEXUS_REPO="powerplatform-artifacts"
    
    # Validate
    if [ -z "$NEXUS_PASSWORD" ]; then
        echo "❌ NEXUS_PASSWORD not set"
        return 1
    fi
    
    echo "📋 Listing artifacts in repository..."
    echo "  URL: $NEXUS_URL"
    echo "  Repository: $NEXUS_REPO"
    echo ""
    
    # List
    RESPONSE=$(curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        "$NEXUS_URL/service/rest/v1/search?repository=$NEXUS_REPO&name=main-solution")
    
    if echo "$RESPONSE" | grep -q "main-solution"; then
        echo "✅ Repository accessible"
        echo "   Contents:"
        echo "$RESPONSE" | grep -o '"name":"[^"]*"' | head -5 | sed 's/"name":"/     - /' | sed 's/"//'
        return 0
    else
        echo "❌ Failed to list artifacts"
        echo "   Response: $RESPONSE"
        return 1
    fi
}

# ============================================================================
# TEST: Verify Credentials
# ============================================================================
test_nexus_credentials() {
    echo "🧪 Testing Nexus Credentials..."
    echo ""
    
    # Configuration
    NEXUS_URL="${NEXUS_URL:-https://nexus.company.com}"
    NEXUS_USERNAME="${NEXUS_USERNAME:-powerplatform-ci}"
    NEXUS_PASSWORD="${NEXUS_PASSWORD}"
    
    # Validate
    if [ -z "$NEXUS_PASSWORD" ]; then
        echo "❌ NEXUS_PASSWORD not set"
        echo "Usage: export NEXUS_PASSWORD=... && $0"
        return 1
    fi
    
    echo "🔐 Verifying Nexus credentials..."
    echo "  URL: $NEXUS_URL"
    echo "  Username: $NEXUS_USERNAME"
    echo ""
    
    # Status check
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        "$NEXUS_URL/service/rest/api/v1/status")
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
        if [ "$HTTP_CODE" = "200" ]; then
            echo "✅ Credentials valid - Nexus is accessible"
            return 0
        else
            echo "❌ Credentials invalid (401 Unauthorized)"
            echo "   Check NEXUS_PASSWORD"
            return 1
        fi
    else
        echo "❌ Cannot reach Nexus (HTTP $HTTP_CODE)"
        echo "   Check NEXUS_URL and network connectivity"
        return 1
    fi
}

# ============================================================================
# MAIN: Run All Tests
# ============================================================================
run_all_tests() {
    echo "╔════════════════════════════════════════════╗"
    echo "║  Nexus Upload/Download Integration Tests  ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    
    # Check environment
    if [ -z "$NEXUS_PASSWORD" ]; then
        echo "⚠️  Setting up test environment..."
        echo ""
        echo "Required: export NEXUS_PASSWORD=your_password"
        echo "Optional: export NEXUS_URL=https://nexus.company.com"
        echo "Optional: export NEXUS_USERNAME=powerplatform-ci"
        echo ""
        echo "Example:"
        echo "  export NEXUS_URL=https://nexus.company.com"
        echo "  export NEXUS_USERNAME=powerplatform-ci"
        echo "  export NEXUS_PASSWORD=SecureP@ssw0rd123!"
        echo "  $0"
        echo ""
        return 1
    fi
    
    PASSED=0
    FAILED=0
    
    # Test 1: Credentials
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 1: Verify Credentials"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if test_nexus_credentials; then
        ((PASSED++))
    else
        ((FAILED++))
        echo "⚠️  Skipping remaining tests - credentials required"
        return 1
    fi
    echo ""
    
    # Test 2: Upload
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 2: Upload Artifact"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if test_nexus_upload; then
        ((PASSED++))
    else
        ((FAILED++))
    fi
    echo ""
    
    # Test 3: Download
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 3: Download Artifact"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if test_nexus_download; then
        ((PASSED++))
    else
        ((FAILED++))
    fi
    echo ""
    
    # Test 4: List
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 4: List Artifacts"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if test_nexus_list; then
        ((PASSED++))
    else
        ((FAILED++))
    fi
    echo ""
    
    # Summary
    echo "╔════════════════════════════════════════════╗"
    echo "║  Test Results Summary                      ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    echo "Passed: $PASSED/4 ✅"
    echo "Failed: $FAILED/4 ❌"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo "✅ All tests passed! Nexus integration ready."
        return 0
    else
        echo "❌ Some tests failed. Check configuration."
        return 1
    fi
}

# ============================================================================
# HELP
# ============================================================================
show_help() {
    echo "Nexus Upload & Download Test Suite"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  all              Run all tests (default)"
    echo "  credentials      Test Nexus credentials"
    echo "  upload           Test artifact upload"
    echo "  download [ver]   Test artifact download (optional: specific version)"
    echo "  list             List artifacts in repository"
    echo ""
    echo "Environment Variables:"
    echo "  NEXUS_URL        Nexus server URL (default: https://nexus.company.com)"
    echo "  NEXUS_USERNAME   Service account username (default: powerplatform-ci)"
    echo "  NEXUS_PASSWORD   Service account password (REQUIRED)"
    echo ""
    echo "Examples:"
    echo "  # Test all functionality"
    echo "  export NEXUS_PASSWORD=SecurePass123!"
    echo "  $0 all"
    echo ""
    echo "  # Test single function"
    echo "  export NEXUS_PASSWORD=SecurePass123!"
    echo "  $0 credentials"
    echo ""
    echo "  # Test download specific version"
    echo "  export NEXUS_PASSWORD=SecurePass123!"
    echo "  $0 download 1.0.45"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
COMMAND="${1:-all}"

case "$COMMAND" in
    all)
        run_all_tests
        ;;
    credentials)
        test_nexus_credentials
        ;;
    upload)
        test_nexus_upload
        ;;
    download)
        test_nexus_download "$2"
        ;;
    list)
        test_nexus_list
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
