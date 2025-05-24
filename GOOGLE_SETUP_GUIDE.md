# Google Calendar Integration Setup Guide

This guide will help you fix the Google Calendar login issue in your Flutter app (v2.8.3).

## Issues Identified
- Missing Google Services configuration files
- Incomplete Android toolchain setup
- OAuth client configuration may be incomplete

## Step-by-Step Setup

### 1. Google Cloud Console Setup

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create or select a project**
3. **Enable APIs**:
   - Go to "APIs & Services" > "Library"
   - Enable "Google Calendar API"
   - Enable "Google Sign-In API" (if available)

4. **Create OAuth 2.0 Credentials**:
   - Go to "APIs & Services" > "Credentials"
   - Click "+ CREATE CREDENTIALS" > "OAuth 2.0 Client IDs"
   - Create credentials for:
     - **Web application** (for testing and token refresh)
     - **Android** (with package name: `ie.qqrxi.spdrivercalendar`)
     - **iOS** (with bundle ID: `ie.qqrxi.spdrivercalendar`)

### 2. Android Configuration

1. **Get SHA-1 fingerprint**:
   ```bash
   # For debug keystore (development)
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # For release keystore (production)
   keytool -list -v -keystore path/to/your/release.keystore -alias your_alias
   ```

2. **Add SHA-1 to Google Cloud Console**:
   - In your Android OAuth client
   - Add the SHA-1 fingerprint you obtained above

3. **Download google-services.json**:
   - From Google Cloud Console > "APIs & Services" > "Credentials"
   - Download and place it in `android/app/google-services.json`
   - **IMPORTANT**: Replace the template file with the real one

### 3. iOS Configuration

1. **Download GoogleService-Info.plist**:
   - From Google Cloud Console
   - Place it in `ios/Runner/GoogleService-Info.plist`
   - **IMPORTANT**: Replace the template file with the real one

2. **Update Info.plist URL scheme**:
   - Replace `YOUR_REVERSED_CLIENT_ID` in `ios/Runner/Info.plist`
   - Use the REVERSED_CLIENT_ID from your GoogleService-Info.plist

### 4. Fix Android Toolchain Issues

Run these commands to fix Android setup:

```bash
# Accept Android licenses
flutter doctor --android-licenses

# Install command line tools (if needed)
# Open Android Studio > SDK Manager > SDK Tools > Android SDK Command-line Tools
```

### 5. Update Google Sign-In Configuration

If you're still having issues, you may need to specify the client ID explicitly:

```dart
// In your GoogleCalendarService, try adding the client ID:
static GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/calendar.events',
  ],
  // Add this line with your web client ID
  serverClientId: "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
  forceCodeForRefreshToken: false,
);
```

### 6. Testing OAuth Setup

1. **Test Environment Setup**:
   - Your app is currently in "testing" mode
   - Add test users in Google Cloud Console > "OAuth consent screen" > "Test users"
   - Add your Google account as a test user

2. **Publishing (Optional)**:
   - For public release, submit your app for verification
   - This removes the testing restrictions

### 7. Debugging Steps

1. **Check Console Logs**:
   ```bash
   flutter logs
   ```

2. **Verify Configuration**:
   - Ensure package names match exactly
   - Verify bundle IDs are consistent
   - Check that all OAuth clients are properly configured

3. **Test Different Accounts**:
   - Try with the Google account that's added as a test user
   - Ensure the account has access to Google Calendar

### 8. Common Issues and Solutions

**Issue**: "only be accessed by developer-approved testers"
- **Solution**: Add your Google account as a test user in OAuth consent screen

**Issue**: "Sign-in canceled or failed"
- **Solution**: Check configuration files are properly placed and contain real data

**Issue**: "PlatformException: network_error"
- **Solution**: Check internet connection and API quotas

**Issue**: "Invalid client" errors
- **Solution**: Verify package name/bundle ID matches OAuth client configuration

### 9. File Checklist

Make sure these files exist and contain real data (not template placeholders):

- ✅ `android/app/google-services.json` (real file from Google Cloud Console)
- ✅ `ios/Runner/GoogleService-Info.plist` (real file from Google Cloud Console)
- ✅ `ios/Runner/Info.plist` (updated with correct REVERSED_CLIENT_ID)
- ✅ Android build.gradle files updated with Google Services plugin

### 10. Next Steps

After completing this setup:

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test the Google Sign-In flow**
3. **Verify Calendar API access**

## Need Help?

If you're still experiencing issues:

1. Check the specific error messages in the logs
2. Verify all configuration files are in place with real data
3. Ensure your Google account is added as a test user
4. Try with a fresh Flutter clean build

## Security Note

**Never commit your real `google-services.json` or `GoogleService-Info.plist` files to version control!**

Add them to your `.gitignore`:
```
# Google Services
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
``` 