# 🔐 API Security Guide

## Overview

This document outlines how API keys are secured in the IoT Parking app.

## ⚠️ IMPORTANT: Before Production Deployment

### 1. **API Key Security Status**

- ✅ **Google Maps API Key**: Secured in `android/local.properties`
- ✅ **Firebase Keys**: Currently in code (less critical, but can be secured)
- ✅ **Build Configuration**: Configured to use environment variables

### 2. **Current API Keys (CHANGE THESE FOR PRODUCTION!)**

```
Google Maps API Key: AIzaSyDY6Xx10omIllIivBo4TOiegLMRvm2E7Xs
Firebase API Key: AIzaSyDEcOKMoqUMkmxEG3Gmh49HlaZ7MYBLoJU
```

## 🚀 Production Deployment Steps

### 1. **Generate New API Keys**

```powershell
# Go to Google Cloud Console
# 1. Create new restricted API keys for production
# 2. Restrict Maps API key to your app's package name and SHA-1 fingerprint
# 3. Update local.properties with new keys
```

### 2. **Create Production Signing Key**

```powershell
# Generate production keystore (DO THIS ONCE!)
keytool -genkey -v -keystore android/app/release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Update build.gradle.kts with signing config
```

### 3. **Build for Production**

```powershell
# Set environment variables
$env:MAPS_API_KEY = "your_new_production_api_key"

# Run production build
./scripts/build_prod.ps1
```

## 🔧 Development Workflow

### Local Development

```powershell
# Edit android/local.properties to add your API keys
MAPS_API_KEY=your_development_api_key

# Build and run
flutter run
```

### Team Development

1. Each developer creates their own `android/local.properties`
2. Never commit this file to Git
3. Share API keys through secure channels only

## 🛡️ Security Features Implemented

### ✅ **API Key Protection**

- Keys stored in `local.properties` (not committed to Git)
- AndroidManifest uses placeholders: `${MAPS_API_KEY}`
- Build system injects keys at compile time

### ✅ **Production Hardening**

- Code obfuscation enabled (`minifyEnabled = true`)
- Resource shrinking enabled (`shrinkResources = true`)
- ProGuard rules configured
- Debug information separated

### ✅ **Environment Detection**

- `Environment.isDevelopment` - for dev-specific features
- `Environment.isProduction` - for production-only security
- `Environment.validateConfiguration()` - ensures keys are set

## 🚨 Security Checklist Before Release

- [ ] **New API keys generated** for production
- [ ] **API keys restricted** in Google Cloud Console
- [ ] **Production keystore created** and configured
- [ ] **Code obfuscation enabled** and tested
- [ ] **No hardcoded secrets** in source code
- [ ] **Firebase security rules** configured
- [ ] **Network security config** enabled
- [ ] **App signed with production key**

## 🔍 Verify Security

```powershell
# Check for hardcoded API keys
Select-String -Pattern "AIza" -Path "lib","android" -Recurse

# Should return NO results after securing
```

## 📞 Emergency Response

If API keys are compromised:

1. **Immediately revoke** old keys in Google Cloud Console
2. **Generate new keys** with proper restrictions
3. **Update local.properties** with new keys
4. **Rebuild and redeploy** the app
5. **Force app update** if keys were in released version

## 📝 Notes

- `local.properties` is in `.gitignore` - never commit it
- Each environment (dev/staging/prod) should have separate API keys
- Monitor API usage in Google Cloud Console for suspicious activity
