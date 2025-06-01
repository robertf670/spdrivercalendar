# Google Calendar Integration Setup Guide

## Overview

This app now uses the `google_sign_in` package for Google Calendar integration, which provides a more reliable and CI/CD-friendly authentication flow.

## Prerequisites

- Google Cloud Console project
- Android development environment
- GitHub repository with Actions enabled

## Setup Steps

### 1. Google Cloud Console Configuration

#### 1.1 Create or Select Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Note down the **Project ID**

#### 1.2 Enable APIs
1. Navigate to **APIs & Services** > **Library**
2. Enable the following APIs:
   - **Google Calendar API**
   - **Google Sign-In API** (if available)

#### 1.3 Configure OAuth Consent Screen
1. Go to **APIs & Services** > **OAuth consent screen**
2. Choose **External** user type
3. Fill in required information:
   - **App name**: Spare Driver Calendar
   - **User support email**: Your email
   - **Developer contact**: Your email
4. **Add Scopes**:
   - `../auth/userinfo.email`
   - `../auth/userinfo.profile` 
   - `../auth/calendar`
   - `../auth/calendar.events`
5. **Add Test Users** (CRITICAL):
   - Add your Google account email
   - Add any other accounts that need access during testing

#### 1.4 Create OAuth 2.0 Credentials

**Android Client**:
1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **OAuth 2.0 Client IDs**
3. Application type: **Android**
4. Name: `SPDriverCalendar Android`
5. Package name: `ie.qqrxi.spdrivercalendar`
6. SHA-1 certificate fingerprint: See [Getting SHA-1 Fingerprints](#getting-sha-1-fingerprints)

**Web Client** (Optional but recommended):
1. Click **+ CREATE CREDENTIALS** > **OAuth 2.0 Client IDs**
2. Application type: **Web application**
3. Name: `SPDriverCalendar Web`

### 2. Getting SHA-1 Fingerprints

#### 2.1 Debug Keystore (Development)
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

#### 2.2 Release Keystore (Production)
```bash
keytool -list -v -keystore /path/to/your/release-key.keystore -alias your-key-alias | grep SHA1
```

#### 2.3 GitHub Actions Keystore
The GitHub Actions workflow will display the SHA-1 fingerprint in the build logs. Look for:
```
=== GitHub Actions SHA-1 Fingerprint ===
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Important**: Add this SHA-1 to your Android OAuth client in Google Cloud Console.

### 3. Download google-services.json

1. In Google Cloud Console, go to **APIs & Services** > **Credentials**
2. Find your Android OAuth 2.0 Client ID
3. Click the download button to get `google-services.json`
4. Place this file at `android/app/google-services.json`

### 4. GitHub Actions Setup

#### 4.1 Set Repository Secrets

Go to your GitHub repository **Settings** > **Secrets and variables** > **Actions** and add:

**Required Secrets**:
- `GOOGLE_SERVICES_JSON_CONTENT`: Contents of your `google-services.json` file
- `DEBUG_KEYSTORE_BASE64`: Base64-encoded debug keystore (optional but recommended for consistency)

**Creating GOOGLE_SERVICES_JSON_CONTENT**:
```bash
# Copy the entire contents of google-services.json
cat android/app/google-services.json
# Paste the entire JSON content as the secret value
```

**Creating DEBUG_KEYSTORE_BASE64**:
```bash
# If you have a specific debug keystore you want to use
base64 -i ~/.android/debug.keystore
# Use the output as the secret value
```

#### 4.2 Workflow Configuration

The workflow is already configured to:
- ✅ Handle missing secrets gracefully
- ✅ Display SHA-1 fingerprints for Google Cloud Console configuration
- ✅ Verify Google Sign-In package configuration
- ✅ Create fallback google-services.json if secrets aren't available

### 5. Local Development Setup

#### 5.1 Android Configuration
Ensure your `android/app/google-services.json` exists and contains your real configuration.

#### 5.2 Testing
1. **Debug builds**: Use your development SHA-1 fingerprint
2. **Release builds**: Use your release keystore SHA-1 fingerprint

### 6. Troubleshooting

#### 6.1 Common Issues

**"Sign-in failed" or "Network error"**:
- ✅ Verify APIs are enabled in Google Cloud Console
- ✅ Check that your Google account is added as a test user
- ✅ Confirm SHA-1 fingerprint is correctly added to OAuth client

**"App not verified" or "Testing mode" errors**:
- ✅ Add your Google account as a test user in OAuth consent screen
- ✅ Ensure the OAuth consent screen is properly configured

**"Client not found" errors**:
- ✅ Verify `google-services.json` matches your package name
- ✅ Check that the Android OAuth client is properly configured

**CI/CD build failures**:
- ✅ Ensure `GOOGLE_SERVICES_JSON_CONTENT` secret is set
- ✅ Check workflow logs for SHA-1 fingerprint and add to Google Cloud Console
- ✅ Verify package name matches across all configurations

#### 6.2 Debug Commands

**Check Google Services configuration**:
```bash
# Verify google-services.json exists and is valid
cat android/app/google-services.json | jq .

# Check for Google Sign-In package
grep "google_sign_in:" pubspec.yaml
```

**Test signing configuration**:
```bash
# Debug signing report
cd android && ./gradlew signingReport

# Build and check for Google Services
flutter build apk --debug
```

### 7. Security Best Practices

#### 7.1 Secrets Management
- ❌ Never commit `google-services.json` to version control
- ✅ Use GitHub Secrets for CI/CD
- ✅ Use different OAuth clients for debug/release builds
- ✅ Regularly rotate OAuth client secrets

#### 7.2 OAuth Configuration
- ✅ Use test users during development
- ✅ Restrict OAuth scopes to minimum required
- ✅ Monitor OAuth usage in Google Cloud Console

### 8. Production Release Checklist

Before releasing to production:

- [ ] Production OAuth client created with release keystore SHA-1
- [ ] OAuth consent screen configured for external users (if needed)
- [ ] Test users added for beta testing
- [ ] GitHub Actions secrets properly configured
- [ ] Release builds tested with Google Calendar features
- [ ] Backup authentication methods considered

### 9. Migration from Previous Implementation

If migrating from the old credential_manager/flutter_appauth implementation:

1. ✅ Updated `pubspec.yaml` to use `google_sign_in`
2. ✅ Replaced `GoogleCalendarService` with new implementation
3. ✅ Updated UI components to use new authentication flow
4. ✅ Cleaned up old dependencies and token management
5. ✅ Updated CI/CD workflow for new package requirements

### 10. Support and Resources

- **Google Sign-In Flutter Package**: https://pub.dev/packages/google_sign_in
- **Google APIs Flutter Package**: https://pub.dev/packages/googleapis
- **Google Cloud Console**: https://console.cloud.google.com/
- **OAuth 2.0 Scopes**: https://developers.google.com/identity/protocols/oauth2/scopes

### 11. Example google-services.json Structure

```json
{
  "project_info": {
    "project_number": "1051329330296",
    "project_id": "your-project-id"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:1051329330296:android:your-app-id",
        "android_client_info": {
          "package_name": "ie.qqrxi.spdrivercalendar"
        }
      },
      "oauth_client": [
        {
          "client_id": "your-client-id.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "ie.qqrxi.spdrivercalendar",
            "certificate_hash": "your-sha1-fingerprint"
          }
        }
      ],
      "api_key": [
        {
          "current_key": "your-api-key"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

---

**Note**: This implementation provides a more reliable and maintainable approach to Google Calendar integration that works well with both local development and CI/CD pipelines. 