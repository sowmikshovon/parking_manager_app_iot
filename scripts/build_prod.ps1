# Production build script
# This builds the app with production configuration and security hardening
Write-Host "🚀 Building production app bundle..." -ForegroundColor Green

# Ensure API keys are set
if (-not $env:MAPS_API_KEY) {
    Write-Host "❌ Error: MAPS_API_KEY environment variable not set!" -ForegroundColor Red
    Write-Host "Set it with: `$env:MAPS_API_KEY='your_api_key_here'" -ForegroundColor Yellow
    exit 1
}

# Build production app bundle with security features
flutter build appbundle --release `
  --dart-define=PRODUCTION=true `
  --dart-define=DEBUG=false `
  --dart-define=MAPS_API_KEY=$env:MAPS_API_KEY `
  --obfuscate `
  --split-debug-info=build/debug-info

Write-Host "✅ Production build complete!" -ForegroundColor Green
Write-Host "📦 App bundle location: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Cyan

# Security verification
Write-Host "🔍 Verifying no hardcoded API keys..." -ForegroundColor Yellow
$apiKeyCheck = Select-String -Pattern "AIza" -Path "lib/*.dart", "android/*.xml" -Recurse 2>$null
if ($apiKeyCheck) {
    Write-Host "⚠️  Warning: Found potential hardcoded API keys!" -ForegroundColor Red
    $apiKeyCheck | ForEach-Object { Write-Host "  $($_.Filename):$($_.LineNumber) - $($_.Line.Trim())" }
} else {
    Write-Host "✅ No hardcoded API keys found!" -ForegroundColor Green
}
