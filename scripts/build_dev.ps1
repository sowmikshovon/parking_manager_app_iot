# Development build script
# This builds the app with development configuration
Write-Host "🔨 Building development APK..." -ForegroundColor Green

flutter build apk --debug `
  --dart-define=DEBUG=true `
  --dart-define=MAPS_API_KEY=$env:MAPS_API_KEY

Write-Host "✅ Development build complete!" -ForegroundColor Green
