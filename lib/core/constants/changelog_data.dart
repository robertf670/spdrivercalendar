final Map<String, List<Map<String, String>>> changelogData = {
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