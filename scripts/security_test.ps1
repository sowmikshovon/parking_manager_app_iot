# Security Test Script for Parking Manager IoT App
# This script verifies that API keys are properly secured

Write-Host "🔐 Running Security Tests..." -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan

$testsPassed = 0
$testsTotal = 0

function Test-SecurityFeature {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$SuccessMessage,
        [string]$FailureMessage
    )
    
    $script:testsTotal++
    Write-Host "`n🧪 Testing: $TestName" -ForegroundColor Yellow
    
    try {
        $result = & $TestScript
        if ($result) {
            Write-Host "✅ $SuccessMessage" -ForegroundColor Green
            $script:testsPassed++
        } else {
            Write-Host "❌ $FailureMessage" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Test failed with error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 1: Check if local.properties contains API keys
Test-SecurityFeature -TestName "API Keys in local.properties" -TestScript {
    $localProps = Get-Content "android\local.properties" -ErrorAction SilentlyContinue
    return ($localProps -match "MAPS_API_KEY=")
} -SuccessMessage "API keys found in local.properties" -FailureMessage "API keys not found in local.properties"

# Test 2: Check if AndroidManifest uses placeholders
Test-SecurityFeature -TestName "AndroidManifest uses placeholders" -TestScript {
    $manifest = Get-Content "android\app\src\main\AndroidManifest.xml" -Raw
    return ($manifest -match '\$\{MAPS_API_KEY\}' -and $manifest -notmatch 'AIza[A-Za-z0-9_-]{35}')
} -SuccessMessage "AndroidManifest uses secure placeholders" -FailureMessage "AndroidManifest contains hardcoded API keys"

# Test 3: Check if local.properties is in .gitignore
Test-SecurityFeature -TestName ".gitignore protection" -TestScript {
    $gitignore = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
    return ($gitignore -match "local\.properties")
} -SuccessMessage "local.properties is protected in .gitignore" -FailureMessage "local.properties not found in .gitignore"

# Test 4: Check for hardcoded API keys in source code
Test-SecurityFeature -TestName "No hardcoded API keys in source" -TestScript {
    $hardcodedKeys = Select-String -Pattern "AIza[A-Za-z0-9_-]{35}" -Path "lib\*.dart" -Recurse 2>$null
    return ($hardcodedKeys.Count -eq 0)
} -SuccessMessage "No hardcoded API keys found in source code" -FailureMessage "Hardcoded API keys found in source code"

# Test 5: Check build configuration
Test-SecurityFeature -TestName "Build configuration security" -TestScript {
    $buildGradle = Get-Content "android\app\build.gradle.kts" -Raw
    return ($buildGradle -match "manifestPlaceholders" -and $buildGradle -match "isMinifyEnabled = true")
} -SuccessMessage "Build configuration includes security features" -FailureMessage "Build configuration missing security features"

# Test 6: Check if environment config exists
Test-SecurityFeature -TestName "Environment configuration" -TestScript {
    return (Test-Path "lib\config\environment.dart")
} -SuccessMessage "Environment configuration file exists" -FailureMessage "Environment configuration file missing"

# Test 7: Verify production build scripts
Test-SecurityFeature -TestName "Production build scripts" -TestScript {
    $devScript = Test-Path "scripts\build_dev.ps1"
    $prodScript = Test-Path "scripts\build_prod.ps1"
    return ($devScript -and $prodScript)
} -SuccessMessage "Build scripts are configured" -FailureMessage "Build scripts are missing"

# Test 8: Check for debug prints in production code
Test-SecurityFeature -TestName "No debug prints in production" -TestScript {
    $debugPrints = Select-String -Pattern "print\(" -Path "lib\*.dart" -Recurse 2>$null | Where-Object { $_.Line -notmatch "//.*print\(" }
    return ($debugPrints.Count -lt 5) # Allow some debug prints, but not too many
} -SuccessMessage "Minimal debug output in code" -FailureMessage "Too many debug prints found (security risk)"

# Summary
Write-Host "`n" -NoNewline
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🔐 SECURITY TEST SUMMARY" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $testsPassed / $testsTotal" -ForegroundColor $(if ($testsPassed -eq $testsTotal) { "Green" } else { "Yellow" })

if ($testsPassed -eq $testsTotal) {
    Write-Host "`n🎉 ALL SECURITY TESTS PASSED!" -ForegroundColor Green
    Write-Host "Your app is ready for production deployment." -ForegroundColor Green
} elseif ($testsPassed -ge ($testsTotal * 0.8)) {
    Write-Host "`n⚠️  MOST TESTS PASSED" -ForegroundColor Yellow
    Write-Host "Address remaining issues before production deployment." -ForegroundColor Yellow
} else {
    Write-Host "`n❌ SECURITY ISSUES DETECTED" -ForegroundColor Red
    Write-Host "Fix security issues before production deployment!" -ForegroundColor Red
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review any failed tests above" -ForegroundColor White
Write-Host "2. Generate new API keys for production" -ForegroundColor White
Write-Host "3. Create production signing keystore" -ForegroundColor White
Write-Host "4. Run: .\scripts\build_prod.ps1" -ForegroundColor White
Write-Host "5. Test on real devices" -ForegroundColor White

# Return exit code based on test results
if ($testsPassed -eq $testsTotal) {
    exit 0
} else {
    exit 1
}
