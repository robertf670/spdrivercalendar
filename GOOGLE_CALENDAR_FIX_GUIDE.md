# Google Calendar Sign-In Fix Guide

## Issues Identified

Your Google Calendar sign-in is failing in release builds (and potentially debug builds) due to several configuration issues:

1. **Missing Google Services Plugin Configuration** ✅ **FIXED**
2. **No Real Google Services Configuration File** ❌ **NEEDS SETUP**
3. **Missing SHA-1 Fingerprint for OAuth** ❌ **NEEDS SETUP**
4. **Incomplete Google Cloud Console Configuration** ❌ **NEEDS SETUP**

## Your Current SHA-1 Fingerprint

I've extracted your debug keystore SHA-1 fingerprint:
```
SHA1: 30:EF:94:24:66:4C:28:C7:C8:59:01:3E:DC:BA:EF:21:B2:7F:FD:DF
```

**Note**: Both your debug and release builds currently use the same debug keystore. For production, you'll want to create a proper release keystore.

## Step-by-Step Fix Process

### 1. Set Up Google Cloud Console (CRITICAL)

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create a new project** (or select existing one):
   - Project name: "SPDriverCalendar" (or your preferred name)
   - Note down the Project ID

3. **Enable Required APIs**:
   - Go to "APIs & Services" > "Library"
   - Enable "Google Calendar API"
   - Enable "Google Sign-In API" (if available)

4. **Configure OAuth Consent Screen**:
   - Go to "APIs & Services" > "OAuth consent screen"
   - Choose "External" user type
   - Fill in required fields:
     - App name: "Spare Driver Calendar"
     - User support email: [your email]
     - Developer contact: [your email]
   - **Add Scopes**:
     - `../auth/userinfo.email`
     - `../auth/calendar`
     - `../auth/calendar.events`
   - **Add Test Users** (CRITICAL):
     - Add your Google account email as a test user
     - This is why sign-in fails - you need to be a test user!

5. **Create OAuth 2.0 Credentials**:
   
   **Android Client**:
   - Go to "APIs & Services" > "Credentials"
   - Click "+ CREATE CREDENTIALS" > "OAuth 2.0 Client IDs"
   - Application type: "Android"
   - Name: "SPDriverCalendar Android"
   - Package name: `ie.qqrxi.spdrivercalendar`
   - SHA-1 certificate fingerprint: `30:EF:94:24:66:4C:28:C7:C8:59:01:3E:DC:BA:EF:21:B2:7F:FD:DF`
   
   **Web Client** (Required for token refresh):
   - Click "+ CREATE CREDENTIALS" > "OAuth 2.0 Client IDs"
   - Application type: "Web application"
   - Name: "SPDriverCalendar Web"
   - No restrictions needed for now

6. **Download Configuration Files**:
   - Click on your Android OAuth client
   - Download `google-services.json` 
   - **Save this file as `android/app/google-services.json`** (replace the template)

### 2. Update Flutter Code with Web Client ID

You'll need to add the Web Client ID to your GoogleSignIn configuration:

```dart
// In lib/google_calendar_service.dart, update the GoogleSignIn initialization:
static GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/calendar.events',
  ],
  // Add your Web Client ID here (get it from Google Cloud Console)
  serverClientId: "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
  forceCodeForRefreshToken: false,
);
```

### 3. Enable Google Services Plugin (ALREADY DONE)

The Google Services plugin has been configured in your build files.

### 4. Test the Setup

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Test debug build**:
   ```bash
   flutter build apk --debug
   flutter install
   ```

3. **Test release build**:
   ```bash
   flutter build apk --release
   ```

### 5. For Production Release

When you're ready for production:

1. **Create a release keystore**:
   ```bash
   keytool -genkey -v -keystore release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```

2. **Get the release SHA-1**:
   ```bash
   keytool -list -v -keystore release-key.keystore -alias release
   ```

3. **Add the release SHA-1 to your Android OAuth client** in Google Cloud Console

4. **Configure release signing** in `android/app/build.gradle.kts`

## Common Issues and Solutions

### Issue: "only be accessed by developer-approved testers"
**Solution**: Add your Google account as a test user in OAuth consent screen

### Issue: "Sign-in canceled or failed"
**Solution**: 
- Verify `google-services.json` is the real file (not template)
- Check SHA-1 fingerprint matches exactly
- Ensure package name is correct: `ie.qqrxi.spdrivercalendar`

### Issue: "PlatformException: network_error"
**Solution**: 
- Check internet connection
- Verify APIs are enabled in Google Cloud Console
- Check API quotas

### Issue: Release build fails to sign in but debug works
**Solution**: 
- Add release keystore SHA-1 to Google Cloud Console
- Ensure both debug and release use proper keystores

## Testing Checklist

- [ ] Google Cloud Console project created
- [ ] Calendar API enabled
- [ ] OAuth consent screen configured with test users
- [ ] Android OAuth client created with correct SHA-1
- [ ] Web OAuth client created
- [ ] Real `google-services.json` file downloaded and placed
- [ ] Web Client ID added to Flutter code
- [ ] Your Google account added as test user
- [ ] Clean build successful
- [ ] Sign-in works in debug build
- [ ] Sign-in works in release build

## Quick Debug Commands

```bash
# Check if Google Services plugin is working
flutter build apk --debug

# Check signing report
cd android && ./gradlew signingReport

# Check if real google-services.json exists
ls -la android/app/google-services.json
```

## Security Notes

- Never commit real `google-services.json` to version control
- The template files are safe to commit
- Store release keystore securely for production
- Consider using GitHub Secrets for automated builds

## Next Steps After Fix

1. Test the app thoroughly with Google Calendar features
2. Add your release keystore SHA-1 for production builds
3. Consider publishing the OAuth consent screen for public use
4. Set up proper release signing for GitHub Actions builds

## Need Help?

If you encounter issues:
1. Check the exact error messages in `flutter logs`
2. Verify all configuration files are real (not templates)
3. Ensure your Google account is a test user
4. Try the debugging tools in your app's Settings page 