# Quick Google Calendar Setup for v2.8.3

## What I've Fixed:
✅ Added Google Services plugin to Android build files  
✅ Added template configuration files  
✅ Updated iOS configuration for URL schemes  
✅ Added debugging tools in Settings (always accessible)  
✅ Added .gitignore entries for security  

## Now You Need To Do:

### 1. Fix Android Development Environment (Critical)

**Option A: Simple Manual Fix (Recommended if you don't use Android Studio)**

1. **Download Command Line Tools**:
   - Go to: https://developer.android.com/studio#command-tools
   - Download "Command line tools only" for Windows
   - Extract the zip file to a temporary location

2. **Install to the right location**:
   ```powershell
   # Navigate to your Android SDK
   cd C:\Users\Rob\AppData\Local\Android\sdk
   
   # Create the directory structure
   mkdir cmdline-tools\latest -Force
   
   # Copy the contents from extracted 'cmdline-tools' folder to 'latest' folder
   # You'll need to manually copy:
   # - bin folder
   # - lib folder  
   # - NOTICE.txt
   # - source.properties
   ```

3. **Accept licenses**:
   ```powershell
   # Add to PATH temporarily for this session
   $env:PATH += ";C:\Users\Rob\AppData\Local\Android\sdk\cmdline-tools\latest\bin"
   
   # Accept licenses
   sdkmanager --licenses
   ```

**Option B: Use Android Studio (If you're okay with opening it once)**

1. **Open Android Studio** (just this once)
2. **Go to Tools > SDK Manager**
3. **SDK Tools tab > Check "Android SDK Command-line Tools"**
4. **Click Apply and let it download**
5. **Close Android Studio**

**Option C: Quick Bypass (For immediate testing)**

Since your app compiles fine and the error only occurs when the Google Services plugin looks for the config file, you can temporarily disable the plugin to test other features:

1. **Comment out the Google Services plugin temporarily**:
   Edit `android/app/build.gradle.kts` and comment out:
   ```kotlin
   // id("com.google.gms.google-services")  // Comment this out temporarily
   ```

2. **Test your app builds**:
   ```bash
   flutter build apk --debug
   ```

3. **Re-enable when you're ready to set up Google Calendar**

### 2. Get Your SHA-1 Fingerprint (After fixing Android tools)

For now, you can skip this step and use the debugging tools. The SHA-1 is only needed when you set up Google Cloud Console.

### 3. Set Up Google Cloud Console
1. **Go to**: https://console.cloud.google.com/
2. **Create new project** or select existing one
3. **Enable APIs**:
   - Search for "Google Calendar API" and enable it
   - Search for "Google Sign-In API" and enable it (if available)

4. **Create OAuth 2.0 Credentials**:
   - Go to "APIs & Services" > "Credentials"
   - Click "+ CREATE CREDENTIALS" > "OAuth 2.0 Client IDs"
   - **Create these 3 clients**:

   **Web Application:**
   - Name: "SPDriverCalendar Web"
   - No restrictions needed

   **Android:**
   - Name: "SPDriverCalendar Android"
   - Package name: `ie.qqrxi.spdrivercalendar`
   - SHA-1: [Your SHA-1 fingerprint from step 2]

   **iOS:**
   - Name: "SPDriverCalendar iOS"  
   - Bundle ID: `ie.qqrxi.spdrivercalendar`

5. **Configure OAuth Consent Screen**:
   - Go to "APIs & Services" > "OAuth consent screen"
   - Choose "External" user type
   - Fill in required fields:
     - App name: "Spare Driver Calendar"
     - User support email: [your email]
     - Developer contact: [your email]
   - Add scopes:
     - `../auth/calendar`
     - `../auth/calendar.events`
   - **Add Test Users**:
     - Add your Google account email as a test user
     - This is critical - you won't be able to sign in without this!

### 4. Download Configuration Files
1. **Android Configuration**:
   - In Google Cloud Console > Credentials
   - Click on your Android OAuth client
   - Download `google-services.json`
   - **Replace** `android/app/google-services.json.template` with this file
   - **Rename** it to `google-services.json` (remove .template)

2. **iOS Configuration**:
   - Click on your iOS OAuth client  
   - Download `GoogleService-Info.plist`
   - **Replace** `ios/Runner/GoogleService-Info.plist.template` with this file
   - **Rename** it to `GoogleService-Info.plist` (remove .template)

3. **Update iOS URL Scheme**:
   - Open the `GoogleService-Info.plist` you just downloaded
   - Find the `REVERSED_CLIENT_ID` value (looks like `com.googleusercontent.apps.xxxxx`)
   - Open `ios/Runner/Info.plist`
   - Replace `com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID` with your actual REVERSED_CLIENT_ID

### 5. Test the Setup
1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Use the new debugging tools**:
   - Go to Settings in your app
   - Expand "Google Sign-In Debugging" section
   - Try "Test Google Configuration"
   - Try "Force Re-authentication"

### 6. Troubleshooting

**If you get "only be accessed by developer-approved testers":**
- Make sure you added your Google account as a test user in OAuth consent screen

**If you get "Sign-in canceled or failed":**
- Check that configuration files are real files from Google Cloud Console (not templates)
- Verify package names match exactly
- Check SHA-1 fingerprint was added correctly

**If sign-in button does nothing:**
- Check `flutter logs` for error messages
- Use the "Test Google Configuration" tool in settings

**Use the debugging tools I added:**
- In Settings > Google Sign-In Debugging
- "Force Re-authentication" - clears cache and tries fresh sign-in
- "Clear All Google Data" - resets everything
- "Test Google Configuration" - shows what's working/not working

### 7. Quick Test Commands
After setup, run these to test:
```bash
# Test if Android builds
flutter build apk --debug

# Test if everything is configured
flutter run --debug
```

## Security Note
The real `google-services.json` and `GoogleService-Info.plist` files are now in your `.gitignore` and won't be committed to version control. Keep them safe!

## Next Steps After Working
1. For production, generate release SHA-1 and add to Google Cloud Console
2. Consider publishing OAuth consent screen for public use
3. Test on both Android and iOS devices

**The key is fixing the Android toolchain first, then following these steps in order!** 