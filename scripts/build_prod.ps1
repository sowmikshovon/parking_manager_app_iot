# Production build script
# This builds the app with production configuration and security hardening
Write-Host "🚀 Building production app bundle..." -ForegroundColor Green

# Check if .env file exists and load it
if (Test-Path ".env") {
    Write-Host "📝 Loading environment variables from .env file..." -ForegroundColor Yellow
    Get-Content .env | ForEach-Object {
        if ($_ -match "^([^#][^=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

# Ensure required API keys are set
$requiredKeys = @("MAPS_API_KEY", "FIREBASE_ANDROID_API_KEY")
foreach ($key in $requiredKeys) {
    if (-not (Get-ChildItem env: | Where-Object Name -eq $key)) {
        Write-Host "❌ Error: $key environment variable not set!" -ForegroundColor Red
        Write-Host "Either set it manually or add it to your .env file" -ForegroundColor Yellow
        exit 1
    }
}

# Build production app bundle with security features
flutter build appbundle --release `
  --dart-define=PRODUCTION=true `
  --dart-define=DEBUG=false `
  --dart-define=MAPS_API_KEY=$env:MAPS_API_KEY `
  --dart-define=FIREBASE_ANDROID_API_KEY=$env:FIREBASE_ANDROID_API_KEY `
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
