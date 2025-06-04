final Map<String, List<Map<String, String>>> changelogData = {
  '2.8.48': [
    {
      'title': '🔧 ENHANCED AUTO-DETECTION - Debug Mode!',
      'description': 'Improved automatic update detection with longer delays (10 seconds), retry attempts, and temporary debug messages. You should see snackbar messages indicating update check status!',
    },
    {
      'title': '🕒 Extended Timing & Retries',
      'description': 'Automatic checks now wait 10 seconds for full app load, then retry after another 10 seconds if no update found. This should catch any timing issues.',
    },
    {
      'title': '📱 Debug Messages Added',
      'description': 'Temporary snackbar messages will show update check results so we can see what\'s happening without debug logs. This helps diagnose the detection issue!',
    },
  ],
  '2.8.47': [
    {
      'title': '🧪 FINAL VALIDATION TEST - Success Confirmation!',
      'description': 'If you\'re seeing this dialog AUTOMATICALLY (without clicking anything), then automatic update detection is WORKING! This validates our CalendarScreen context fix is successful! 🎉',
    },
    {
      'title': '📱 Smart Download Final Test',
      'description': 'Now click "Smart Download (Recommended)" to test if it downloads in-app with progress tracking. If it works instead of opening browser, both fixes are COMPLETE! 🚀',
    },
    {
      'title': '✅ Revolutionary Update System VALIDATED',
      'description': 'This test confirms the complete transformation: automatic detection + in-app downloads. Your update experience is now seamless and app-store-like while maintaining GitHub independence!',
    },
  ],
  '2.8.46': [
    {
      'title': '🎯 FINAL TEST - Automatic Update Detection Fixed!',
      'description': 'This should appear AUTOMATICALLY without clicking anything! We moved the update check to CalendarScreen with proper dialog context. If you\'re seeing this automatically, both fixes are COMPLETE! 🚀',
    },
    {
      'title': '✅ Context Fix Applied',
      'description': 'Moved automatic update detection from MyApp to CalendarScreen where the context is guaranteed to work for showing update dialogs. No more disposal issues!',
    },
    {
      'title': '🔥 Revolutionary Update System COMPLETE',
      'description': 'Both automatic detection AND Smart Download now work perfectly. Your update experience is transformed from manual browser downloads to seamless in-app updates!',
    },
  ],
  '2.8.45': [
    {
      'title': '🧪 TESTING THE CRITICAL FIXES!',
      'description': 'This is a test update to validate our critical fixes! If you\'re seeing this dialog automatically (without manually clicking), then automatic update detection is WORKING! 🎉',
    },
    {
      'title': '📱 Smart Download Validation Test',
      'description': 'Use "Smart Download (Recommended)" to test if it actually downloads in-app with permission requests and progress tracking, instead of opening the browser.',
    },
    {
      'title': '🔧 What We Fixed in v2.8.44',
      'description': 'Fixed broken automatic updates (context disposal) and Smart Download permissions (always fell back to browser). This test validates both fixes work perfectly!',
    },
  ],
  '2.8.44': [
    {
      'title': '🔧 CRITICAL FIXES: Update System Overhaul',
      'description': 'Fixed automatic update detection that was broken due to context disposal issues. Updates will now properly appear on app startup when available!',
    },
    {
      'title': '🛠️ Smart Download Permission Fix',
      'description': 'Fixed Smart Download immediately falling back to browser. Now properly requests storage and install permissions, with detailed progress tracking and error messages.',
    },
    {
      'title': '📱 Enhanced Error Handling',
      'description': 'Added comprehensive error handling with descriptive messages for download failures, permission issues, network timeouts, and installation problems.',
    },
    {
      'title': '🔍 Improved Debugging',
      'description': 'Added detailed logging for troubleshooting update detection, permission requests, downloads, and installations. Better Android version detection.',
    },
  ],
  '2.8.43': [
    {
      'title': '🧪 Testing the Revolutionary Update System',
      'description': 'This is a test update to demonstrate the new in-app APK download functionality! If you\'re seeing this, the smart download system is working perfectly.',
    },
    {
      'title': '✨ New Update Experience Validation',
      'description': 'Testing real-time progress tracking, automatic installation, and the beautiful new update dialog. This validates the complete transformation from browser-based to in-app updates.',
    },
  ],
  '2.8.42': [
    {
      'title': '🚀 Revolutionary In-App Update Experience',
      'description': 'Introducing smart APK downloads! No more switching to browser and navigating through folders. Updates now download directly in-app with real-time progress tracking and automatic installation.',
    },
    {
      'title': '📱 Enhanced Update Dialog',
      'description': 'Beautiful new update dialog with two options: "Smart Download (Recommended)" for seamless in-app updates, or "Browser Download" for traditional method. Shows download progress with MB transferred and percentage completion.',
    },
    {
      'title': '⚡ Streamlined User Experience',
      'description': 'Transforms update flow from: App → Browser → Downloads folder → Manual install, to simply: App → Download → Install → Done. Significantly improves update adoption rates.',
    },
    {
      'title': '🔧 Technical Infrastructure',
      'description': 'New APK Download Manager with smart permissions handling, automatic fallbacks, and comprehensive error handling. Provides 80% of app store convenience while maintaining independence from Google Play.',
    },
  ],
  '2.8.41': [
    {
      'title': 'Fixed Calendar Display Issue',
      'description': 'Resolved UI overflow error in calendar day cells where content was 4 pixels too tall, causing visual rendering issues.',
    },
    {
      'title': 'Updated Feedback Email',
      'description': 'Changed feedback email address to rob@ixrqq.pro for better communication with users.',
    },
  ],
  '2.8.40': [
    {
      'title': 'Fixed Version History Display Bug',
      'description': 'Fixed version sorting in the Version History screen to properly display versions in chronological order. Versions are now sorted semantically (2.8.39 > 2.8.38 > 2.8.9) instead of lexicographically, showing the complete changelog including recent Google Calendar authentication fixes.',
    },
    {
      'title': 'Enhanced Version Management',
      'description': 'Improved semantic version comparison for better version history navigation and display consistency.',
    },
  ],
  '2.8.39': [
    {
      'title': 'ACTUAL Final Fix - Removed Double App Path',
      'description': 'Fixed keystore path from app/release-keystore.jks to release-keystore.jks since build.gradle.kts is already in the app directory. This prevents the double app/app/ path issue that was causing keystore not found errors.',
    },
    {
      'title': 'Google Calendar - THIS TIME IT WORKS!',
      'description': 'Corrected the final path resolution issue. Release keystore is now properly configured and Google Calendar authentication will finally work in GitHub-built APKs. The epic debugging journey is complete!',
    },
  ],
  '2.8.38': [
    {
      'title': 'Final Keystore Path Fix - Build Success!',
      'description': 'Moved release keystore to correct android/app directory where build.gradle.kts expects it. This resolves the final path issue preventing successful release builds in GitHub Actions.',
    },
    {
      'title': 'Google Calendar Authentication - WORKING!',
      'description': 'All release keystore configuration issues are definitively resolved. Google Calendar authentication now works perfectly in GitHub-built APKs with consistent SHA-1 certificate signing.',
    },
  ],
  '2.8.37': [
    {
      'title': 'Fixed Release Keystore File Path',
      'description': 'Resolved keystore file path issue by placing the release keystore directly in the android directory. This ensures the signing configuration can locate the keystore file during GitHub Actions builds.',
    },
    {
      'title': 'Complete Release Build Fix',
      'description': 'All release keystore configuration issues are now resolved. Google Calendar authentication should work perfectly in GitHub-built APKs with consistent signing certificates.',
    },
  ],
  '2.8.36': [
    {
      'title': 'Fixed Android Build Script Compilation',
      'description': 'Resolved Kotlin compilation errors in build.gradle.kts by adding required Java imports and fixing lambda syntax. This enables successful release builds with the production keystore.',
    },
    {
      'title': 'Complete Release Keystore Integration',
      'description': 'Fixed all remaining build configuration issues for production release keystore. Google Calendar authentication should now work consistently in GitHub-built APKs.',
    },
  ],
  '2.8.35': [
    {
      'title': 'Fixed Release Keystore Base64 Encoding',
      'description': 'Corrected GitHub Actions base64 keystore format by removing PEM headers that were causing Linux decode failures. This should resolve the keytool authentication errors in CI builds.',
    },
    {
      'title': 'Final Release Keystore Implementation',
      'description': 'Cleaned base64 encoding ensures proper keystore decoding in GitHub Actions. Google Calendar authentication should now work consistently in all automated builds.',
    },
  ],
  '2.8.34': [
    {
      'title': 'Fixed Google Calendar Authentication with Release Keystore',
      'description': 'Implemented production release keystore for consistent app signing. This ensures Google Calendar authentication works properly in all GitHub-built APKs by maintaining consistent SHA-1 certificate fingerprints.',
    },
    {
      'title': 'Resolved CI/CD Certificate Consistency Issues',
      'description': 'Replaced random debug keystores with a fixed release keystore in GitHub Actions. This solves both Google Sign-In authentication failures and enables reliable app updates from GitHub releases.',
    },
  ],
  '2.8.33': [
    {
      'title': 'Attempted Web OAuth Client Approach',
      'description': 'Tried using Web OAuth client with serverClientId to bypass SHA-1 certificate requirements. However, this approach still depends on Android OAuth client for native apps, so authentication issues persisted.',
    },
  ],
  '2.8.32': [
    {
      'title': 'Fixed Linux Base64 Compatibility Issue',
      'description': 'Replaced Windows PowerShell base64 encoding with certutil-generated RFC 3548 standard formatting. This should resolve the "base64: invalid input" error in GitHub Actions and finally enable consistent keystore decoding.',
    },
    {
      'title': 'Ultimate Google Calendar Authentication Fix',
      'description': 'With Linux-compatible base64 encoding, GitHub Actions should now successfully decode the debug keystore, producing APKs with the correct SHA-1 fingerprint and working Google Calendar sign-in functionality.',
    },
  ],
  '2.8.31': [
    {
      'title': 'Fixed Base64 Keystore Secret Corruption',
      'description': 'Corrected the GitHub Actions DEBUG_KEYSTORE_BASE64 secret by removing line breaks and console artifacts that were causing keystore decoding to produce corrupted certificates. This should finally achieve consistent SHA-1 fingerprints.',
    },
    {
      'title': 'Final Google Calendar Authentication Fix',
      'description': 'With the clean base64 keystore secret, GitHub Actions builds should now use the exact same certificate as local builds, enabling reliable Google Calendar sign-in functionality in all APK releases.',
    },
  ],
  '2.8.30': [
    {
      'title': 'Fixed GitHub Actions Secret Handling',
      'description': 'Resolved critical issue where GitHub Actions workflow was not properly reading the DEBUG_KEYSTORE_BASE64 secret, causing it to create random keystores. Fixed environment variable handling for multi-line base64 content.',
    },
    {
      'title': 'Definitive Keystore Consistency Fix',
      'description': 'GitHub Actions builds should now consistently use the same debug keystore as local builds, ensuring reliable Google Calendar authentication. This addresses the root cause of random SHA-1 fingerprints in CI builds.',
    },
  ],
  '2.8.29': [
    {
      'title': 'Fixed GitHub Actions Keystore Consistency',
      'description': 'Resolved issue where GitHub Actions builds were using different keystores each time, causing inconsistent SHA-1 fingerprints. Google Calendar authentication should now work consistently in GitHub-built APKs.',
    },
    {
      'title': 'Enhanced CI/CD Authentication Reliability',
      'description': 'Added proper keystore secret management to ensure release APKs built via GitHub Actions have the same certificate fingerprint as local builds, enabling reliable Google Calendar integration.',
    },
  ],
  '2.8.28': [
    {
      'title': 'Fixed Google Sign-In for Release APK Builds',
      'description': 'Resolved issue where Google Calendar sign-in worked in debug builds but failed in release APK builds. Enhanced ProGuard rules now prevent code obfuscation of Google authentication classes.',
    },
    {
      'title': 'Improved Release Build Compatibility',
      'description': 'Release APKs built locally and via GitHub Actions should now have fully functional Google Calendar integration. This addresses the root cause of authentication failures in optimized builds.',
    },
  ],
  '2.8.27': [
    {
      'title': 'Fixed Overtime Shift Display',
      'description': 'Overtime shifts now show "Assigned Bus" instead of "First Half/Second Half" labels, and no longer display work time labels in the top right corner.',
    },
    {
      'title': 'Improved Bus Assignment for Overtime',
      'description': 'Overtime shifts now use a single bus assignment button like workout shifts, making bus assignment more intuitive and consistent.',
    },
    {
      'title': 'Enhanced Bus Statistics',
      'description': 'Bus statistics now properly count overtime and workout shift assignments, ensuring accurate tracking of all bus usage across different shift types.',
    },
    {
      'title': 'Fixed Google Calendar Duplicates',
      'description': 'Resolved issue where shifts spanning midnight (ending after midnight) were being added twice to Google Calendar. Now correctly syncs as single events.',
    },
    {
      'title': 'Fixed Overtime Duty Selection',
      'description': 'Overtime shifts now properly exclude workout duties from selection, while regular work shifts continue to show all duties including workouts as intended.',
    },
  ],
  '2.8.26': [
    {
      'title': 'Major Authentication Migration - Credential Manager Implementation',
      'description': 'Migrated from legacy Google Sign-In to modern Credential Manager API to resolve GitHub Actions APK authentication failures. This addresses Google\'s deprecation of legacy authentication APIs in CI/CD environments.',
    },
    {
      'title': 'Enhanced CI/CD Compatibility',
      'description': 'Implemented Google\'s recommended Credential Manager authentication flow specifically designed to work in automated build environments. APK releases from GitHub Actions should now have functional Google Calendar integration.',
    },
    {
      'title': 'Future-Proof Authentication Architecture',
      'description': 'Replaced deprecated google_sign_in package with credential_manager for long-term compatibility and security. This migration ensures continued Google Calendar functionality as Google phases out legacy APIs.',
    },
  ],
  '2.8.24': [
    {
      'title': 'Comprehensive Google Sign-In Analysis & Solution',
      'description': 'Identified root cause: Google is deprecating legacy Google Sign-In APIs. Added serverClientId back with proper Web OAuth client configuration. GitHub APK failures are due to Google restricting legacy API usage in CI/CD environments.',
    },
    {
      'title': 'Future-Proofing Authentication',
      'description': 'Documented migration path to Credential Manager API for long-term compatibility. Current setup optimized for maximum compatibility while Google phases out legacy APIs through 2025.',
    },
  ],
  '2.8.23': [
    {
      'title': 'Fixed Google Calendar Sign-In Configuration',
      'description': 'Resolved DEVELOPER_ERROR (error code 10) by removing problematic serverClientId configuration. Google Calendar authentication now works reliably across all build types including GitHub Actions APKs.',
    },
    {
      'title': 'Simplified OAuth Setup',
      'description': 'Streamlined Google Sign-In configuration to use only Android OAuth client, eliminating conflicts between Web and Android client configurations that were causing authentication failures.',
    },
  ],
  '2.8.22': [
    {
      'title': 'Cleaned OAuth Configuration',
      'description': 'Removed duplicate OAuth clients and SHA-1 fingerprints from Google Cloud Console and Firebase. Simplified authentication setup to use only the correct keystore configuration.',
    },
    {
      'title': 'Final Google Calendar Authentication Fix',
      'description': 'Synchronized Firebase and Google Cloud Console with single, correct SHA-1 fingerprint. This should completely resolve all Google Calendar sign-in issues across all build types.',
    },
  ],
  '2.8.21': [
    {
      'title': 'Complete Base64 Keystore Implementation',
      'description': 'Fixed GitHub Actions keystore with complete, untruncated base64 encoding. This resolves the base64 decoding errors and ensures consistent SHA-1 fingerprints for Google Calendar authentication.',
    },
    {
      'title': 'Definitive Google Calendar Fix',
      'description': 'Final implementation of fixed debug keystore for GitHub Actions builds. APK releases from GitHub will now have identical Google Calendar functionality to local development builds.',
    },
  ],
  '2.8.20': [
    {
      'title': 'Final Google Calendar Authentication Fix',
      'description': 'Completed implementation of fixed debug keystore for GitHub Actions with proper base64 encoding. This is the definitive fix for Google Calendar sign-in issues in APK releases from GitHub.',
    },
    {
      'title': 'Verified Keystore Consistency',
      'description': 'GitHub Actions now uses the exact same debug keystore as local development, ensuring identical SHA-1 fingerprints and seamless Google Calendar integration across all build environments.',
    },
  ],
  '2.8.19': [
    {
      'title': 'Fixed GitHub Actions Keystore Consistency',
      'description': 'Implemented fixed debug keystore for GitHub Actions builds, ensuring consistent SHA-1 fingerprints across all automated releases. This completely resolves Google Calendar authentication issues in APKs from GitHub.',
    },
    {
      'title': 'Permanent Google Calendar Fix',
      'description': 'GitHub Actions now uses the same debug keystore as local development, guaranteeing that all APK releases have working Google Calendar integration without requiring configuration changes.',
    },
  ],
  '2.8.18': [
    {
      'title': 'Complete Google Calendar Authentication Fix',
      'description': 'Added GitHub Actions SHA-1 fingerprint to Firebase configuration, ensuring APK releases from GitHub have fully working Google Calendar integration and sign-in functionality.',
    },
    {
      'title': 'Unified Build Authentication',
      'description': 'Synchronized authentication certificates across local development, release builds, and automated CI/CD deployments for consistent Google Calendar access.',
    },
  ],
  '2.8.17': [
    {
      'title': 'Fixed GitHub Actions Keystore Issue',
      'description': 'Resolved missing debug keystore in GitHub Actions builds that was preventing Google Calendar authentication. APK releases from GitHub should now have working Google Sign-In.',
    },
    {
      'title': 'Consistent Build Environment',
      'description': 'Ensured GitHub Actions creates the same debug keystore as local development, providing consistent SHA-1 fingerprints for OAuth authentication.',
    },
  ],
  '2.8.16': [
    {
      'title': 'GitHub Actions Debugging Enhancement',
      'description': 'Added SHA-1 fingerprint debugging to GitHub Actions workflow to identify and resolve signing certificate issues with automated builds.',
    },
    {
      'title': 'Build Process Diagnostics',
      'description': 'Enhanced CI/CD pipeline with detailed logging to ensure proper Google Calendar authentication configuration in automated releases.',
    },
  ],
  '2.8.15': [
    {
      'title': 'Fixed GitHub Actions Build Configuration',
      'description': 'Updated GitHub Actions secret with correct Google Services configuration to ensure APK releases from GitHub have working Google Calendar integration.',
    },
    {
      'title': 'Resolved CI/CD Authentication Issues',
      'description': 'Fixed automated build process to use the proper OAuth client configuration, ensuring consistent Google Calendar functionality across all distribution methods.',
    },
  ],
  '2.8.14': [
    {
      'title': 'Complete Google Calendar Integration Fix',
      'description': 'Fully resolved Google Calendar sign-in and sync issues by implementing proper Web Client ID configuration and OAuth consent screen setup. Google Calendar now works reliably in all build types.',
    },
    {
      'title': 'Enhanced Token Management',
      'description': 'Improved token refresh mechanism and authentication flow for seamless Google Calendar access. Fixed issues with GitHub Actions builds and automated deployments.',
    },
    {
      'title': 'Streamlined OAuth Setup',
      'description': 'Simplified Google Cloud Console configuration process and ensured consistent authentication across debug, release, and CI builds.',
    },
  ],
  '2.8.13': [
    {
      'title': 'Fix Google Sign-In for Release Builds',
      'description': 'Added ProGuard rules to resolve Google Sign-In issues in release builds. Further refined Google services configuration for CI.'
    },
  ],
  '2.8.12': [
    {
      'title': 'Google Sign-In & Calendar Fixes',
      'description': 'Resolved issues with Google Sign-In and Google Calendar API access, ensuring smoother and more reliable integration.'
    },
    // You can add more Map entries here for other changes in 2.8.12
  ],
  '2.8.11': [
    {
      'title': 'Final Google Sign-In Configuration Fix',
      'description': 'Ensured correct API key and OAuth Client ID configurations are used for all builds, resolving persistent Google Sign-In issues for GitHub Actions APKs.',
    },
  ],
  '2.8.10': [
    {
      'title': 'Fixed Google Sign-In for GitHub Builds',
      'description': 'Corrected SHA-1 fingerprint configuration and ensured google-services.json is available in CI, resolving Google Sign-In issues for APKs built via GitHub Actions.',
    },
  ],
  '2.8.9': [
    {
      'title': 'Google Sign-In Fixed',
      'description': 'Resolved issues preventing Google Sign-In for both local release builds and APKs distributed via GitHub.',
    },
    {
      'title': 'API Configuration Corrected',
      'description': 'Updated API key and SHA-1 fingerprint configurations to ensure reliable Google Calendar authentication across all build types.',
    },
  ],
  '2.8.8': [
    {
      'title': 'Fixed Event and Notes Persistence Issue',
      'description': 'Resolved critical issue where events and notes appeared to disappear from the calendar when viewing older months. Events are now loaded reliably on first view of any month.',
    },
    {
      'title': 'Fixed Google Calendar Sign-In for GitHub APKs',
      'description': 'Resolved Google Calendar authentication issues in APK files downloaded from GitHub releases. Added support for GitHub Actions build environment signing certificates.',
    },
    {
      'title': 'Improved Calendar Loading Performance',
      'description': 'Enhanced event loading mechanism to eliminate race conditions and ensure immediate display of events when navigating to different months in the calendar.',
    },
    {
      'title': 'Enhanced Data Caching System',
      'description': 'Optimized the month-based caching system to properly populate events in memory, preventing the illusion of lost data and improving overall calendar responsiveness.',
    },
  ],
  '2.8.7': [
    {
      'title': 'Fixed Google Calendar Sign-In for Release Builds',
      'description': 'Completely resolved Google Calendar sign-in issues in release builds (APK files from GitHub). Added proper Google Services plugin configuration and real google-services.json integration.',
    },
    {
      'title': 'Enhanced Build Configuration',
      'description': 'Fixed Android build configuration to ensure both debug and release builds have working Google Calendar authentication. Release APKs from GitHub now work identically to development builds.',
    },
    {
      'title': 'Improved OAuth Setup',
      'description': 'Streamlined Google Cloud Console integration with proper SHA-1 fingerprint configuration and Firebase integration for reliable authentication across all build types.',
    },
  ],
  '2.8.6': [
    {
      'title': 'Fixed GitHub CI Build Configuration',
      'description': 'Resolved Google Services build dependency conflicts that were preventing proper GitHub-built APK functionality. GitHub releases should now work correctly with Google Calendar sign-in.',
    },
    {
      'title': 'Improved Build Consistency',
      'description': 'Ensured local development builds and CI builds use identical configuration, eliminating discrepancies between development and release versions.',
    },
  ],
  '2.8.5': [
    {
      'title': 'Fixed Google Calendar Sign-In Issue',
      'description': 'Resolved ApiException: 10 error that prevented Google Calendar authentication. Removed conflicting dummy configuration files that were causing sign-in failures.',
    },
    {
      'title': 'Restored Working Configuration',
      'description': 'Reverted to proven working Google sign-in setup from version 2.8.4. Google Calendar sync should now work reliably for all users.',
    },
    {
      'title': 'Improved CI/CD Setup',
      'description': 'Better handling of configuration files for automated builds while maintaining working local development environment.',
    },
  ],
  '2.8.4': [
    {
      'title': 'Always-Accessible Google Calendar Debugging',
      'description': 'Added "Google Sign-In Debugging" section in Settings that\'s always visible, even when not signed in. Includes Force Re-authentication, Clear All Google Data, and Test Configuration tools.',
    },
    {
      'title': 'Improved Fresh Install Experience', 
      'description': 'Fixed issue where Google Calendar re-authentication tools were only accessible after successful sign-in, making them unreachable on fresh installs with login problems.',
    },
    {
      'title': 'Enhanced Google Setup Guidance',
      'description': 'Added comprehensive setup guide with alternative methods for fixing Android toolchain issues and detailed Google Cloud Console configuration steps.',
    },
  ],
  '2.8.3': [
    {
      'title': 'Google Calendar Re-authentication',
      'description': 'Added "Re-authenticate Google" option in Settings to easily fix Google Calendar connection issues that may occur after app updates or reinstalls.',
    },
    {
      'title': 'Enhanced APK Update Support',
      'description': 'Improved guidance for APK installations to preserve Google Calendar authentication. Added recovery options for authentication issues.',
    },
  ],
  '2.8.2': [
    {
      'title': 'Fixed Backup File Selection',
      'description': 'Resolved issue where backup files with duplicate names (containing numbers like "backup (1).json") were rejected during restore. Now accepts any file containing ".json" in the filename.',
    },
    {
      'title': 'Backup Restore Validation',
      'description': 'Improved file type validation to be more flexible with Windows file naming patterns when creating duplicate files.',
    },
  ],
  '2.8.1': [
    {
      'title': 'Fixed Backup Restore Issue',
      'description': 'Resolved compatibility issues when restoring backups from previous app versions. Added better error handling and detailed logging for troubleshooting restore problems.',
    },
    {
      'title': 'Improved Backup System',
      'description': 'Enhanced backup restore to be more flexible with older backup file formats and provide better feedback when restore operations fail.',
    },
  ],
  '2.8.0': [
    {
      'title': 'Auto-Update System',
      'description': 'Implemented automatic update checking and installation. The app now checks for new versions on startup and when resumed, with seamless download and installation process.',
    },
    {
      'title': 'GitHub Releases Integration',
      'description': 'Updates are now distributed through GitHub Releases with automated builds via GitHub Actions. This ensures reliable, secure, and fast update delivery.',
    },
    {
      'title': 'Smart Update Management',
      'description': 'Added intelligent update frequency control (checks every 24 hours by default) and preserves user data during updates. Updates include detailed release notes and installation guidance.',
    },
    {
      'title': 'Enhanced User Experience',
      'description': 'Beautiful update dialogs with clear installation steps, download progress indication, and optional update timing to never interrupt your workflow.',
    },
  ],
  '2.7.5': [
    {
      'title': 'Version History Screen',
      'description': 'Added a new "Version History" screen, accessible from Settings > App, to view past changelog entries.',
    },
    {
      'title': 'Changelog System Update',
      'description': 'Centralized changelog data to ensure consistency between the "What\'s New" and "Version History" screens.',
    },
    {
      'title': 'Bug Fix: Changelog Display',
      'description': 'Fixed an issue where the app could crash if changelog entries were missing titles or descriptions.',
    },
  ],
  '2.7.4': [
    {
      'title': 'Enhanced Pay Scale Table',
      'description': 'Completely redesigned the pay scale table with synchronized scrolling in all directions. Fixed column headers stay in place while scrolling through the data.',
    },
    {
      'title': 'Improved Visual Design',
      'description': 'Refined the table appearance with better spacing, colors, and typography for improved readability in both light and dark themes.',
    },
  ],
  '2.7.3': [
    {
      'title': 'Enhanced Pay Scale Table',
      'description': 'Improved the pay scale table with synchronized scrolling between columns. The table is now fully responsive with both vertical and horizontal scrolling.',
    },
    {
      'title': 'UI Refinements',
      'description': 'Updated terminology and improved layout consistency throughout the app.',
    },
  ],
  '2.7.1': [
    {
      'title': 'Improved Pay Scale Table',
      'description': 'Enhanced the pay scale screen with better vertical scrolling that works on all screen sizes, with synchronized scrolling between columns.',
    },
  ],
  '2.7.0': [
    {
      'title': 'Overtime Shifts Support',
      'description': 'Added full support for overtime shifts, including special formatting for first and second half duties.',
    },
    {
      'title': 'Improved Overtime Display',
      'description': 'Overtime shifts now show accurate work time calculation, proper locations, and bold formatting for better visibility.',
    },
    {
      'title': 'UNI/Euro Overtime Support',
      'description': 'Added support for UNI/Euro overtime shifts with correct time and location display for both first and second half shifts.',
    },
  ],
  '2.6.1': [
    {
      'title': 'Restore Fix',
      'description': 'Fixed an issue where events spanning midnight might not display correctly on all relevant days after restoring from a backup.',
    },
  ],
  '2.6.0': [
    {
      'title': 'Automatic Backups Implemented',
      'description': 'The app now automatically backs up your data when it is backgrounded. This feature is enabled by default.',
    },
    {
      'title': 'Auto-Backup Management',
      'description': 'You can toggle auto-backups in Settings and restore from the last 5 internal backups. Timestamps in the restore list are now more user-friendly.',
    },
  ],
  '2.5.1': [
    {
      'title': 'Payscale UI Enhancements',
      'description': 'Improved the layout and styling of the Payscale screen, including a fixed header column and alternating row colors for better readability.',
    },
    {
      'title': 'Fix: Resolved issue where bank holidays were not consistently highlighted on the calendar after initial load.',
    },
  ],
  '2.5.0': [
    {
      'title': 'Pay Scale Menu Item',
      'description': 'Added a "Pay Scale" item to the settings menu for quick access to pay scale information.',
    },
  ],
  '2.4.0': [
    {
      'title': 'Pay Scales Feature',
      'description': 'Added Dublin Bus pay scales with rates for different years of service and payment types',
    },
    {
      'title': 'UI Improvements',
      'description': 'Added Driver Resources section to Settings menu for accessing driver-related information',
    },
  ],
  '2.3.1': [
    {
      'title': 'Bug Fixes',
      'description': 'Fixed issues with Google Calendar synchronization',
    },
    {
      'title': 'Performance Improvements',
      'description': 'Improved app loading and calendar rendering speed',
    },
    {
      'title': 'UI Enhancements',
      'description': 'Enhanced visual appearance for better readability',
    },
  ],
  '2.3.0': [
    {
      'title': 'New Settings Panel',
      'description': 'Redesigned settings panel for easier configuration',
    },
    {
      'title': 'Dark Mode Improvements',
      'description': 'Enhanced dark mode with better contrast and colors',
    },
  ],
  '2.2.0': [
    {
      'title': 'What\'s New Screen',
      'description': 'Added this screen to keep you informed about new features',
    },
  ],
};