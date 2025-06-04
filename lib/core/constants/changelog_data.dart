final Map<String, List<Map<String, String>>> changelogData = {
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