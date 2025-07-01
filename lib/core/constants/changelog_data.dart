final Map<String, List<Map<String, String>>> changelogData = {
  '2.14.6': [
    {
      'title': 'FIXED: GitHub CI Build Compatibility',
      'description': 'Resolved critical Kotlin version compatibility issues that were preventing GitHub CI builds from completing successfully. Updated Kotlin from 1.8.22 to 2.2.0 to meet Firebase library requirements (2.1.0+).',
    },
    {
      'title': 'Enhanced CI Build Performance',
      'description': 'Increased Gradle heap size from 1536M to 4096M to prevent Java heap space errors during automated builds. GitHub Actions now has sufficient memory allocation for complex Firebase and Google services compilation.',
    },
    {
      'title': 'Build System Stability',
      'description': 'Fixed compatibility matrix between Kotlin 2.2.0, Firebase libraries, and Google Play Services. All build environments (local, CI/CD) now use consistent versions ensuring reliable automated releases.',
    },
  ],
  '2.14.5': [
    {
      'title': 'Fixed Assigned Duty Disappearing Issue',
      'description': 'Resolved intermittent issue where assigned duties on spare shifts would occasionally disappear from the UI but remain saved in storage. Improved cache synchronization between in-memory data and persistent storage to ensure assigned duties and their bus assignments always display correctly after being set.',
    },
  ],
  '2.14.4': [
    {
      'title': 'GitHub Actions CI/CD Improvements',
      'description': 'Updated Flutter version in GitHub Actions to 3.32.5 to match local development environment. Resolved build environment consistency issues and improved automated APK generation reliability.',
    },
  ],
  '2.14.3': [
    {
      'title': 'Delete Button Missing for Normal Events',
      'description': 'Fixed issue where normal events with "Spare" in the title were incorrectly treated as spare duty shifts and lost their delete button. Delete button now appears correctly for all normal events regardless of title content.',
    },
  ],
  '2.14.2': [
    {
      'title': 'Enhanced Spare Duty Bus Assignment UI',
      'description': 'Improved bus assignment button to clearly show current status: blue "Add" button when no bus assigned, orange "Edit" button when bus already assigned. Makes it much easier to see if a bus is assigned and modify bus assignments without deleting the entire spare duty.',
    },
    {
      'title': 'Removed Redundant "Assigned:" Text',
      'description': 'Cleaned up spare duty event cards by removing unnecessary "Assigned:" prefix from duty descriptions. Displays cleaner format: "PZ1/50A | 11:47 to 16:15 | Bus: SG292" instead of "Assigned: PZ1/50A | 11:47 to 16:15 | Bus: SG292".',
    },
    {
      'title': 'Normal Event Creation Overflow',
      'description': 'Resolved RenderFlex overflow issue in Add Event dialog where time selection dropdowns caused 1.6px overflow with red warning stripes. Shortened labels from "Hour/Minute" to "H/M" and optimized spacing for all screen sizes.',
    },
    {
      'title': 'Enhanced Normal Event Display',
      'description': 'Normal events (non-work shifts) now display clean, simple time information without work-specific details like break times, route information, or board data. Streamlined interface shows only relevant information for personal appointments and events.',
    },
    {
      'title': 'Compatibility & Stability Updates',
      'description': 'Updated Kotlin compiler to version 2.2.0 and desugar_jdk_libs to 2.1.4 for compatibility with latest Flutter packages. Fixed Google Sign-In API breaking changes by maintaining version 6.3.0 compatibility and resolved notification service updates.',
    },
  ],
  '2.14.1': [
    {
      'title': 'Manual Scrolling for Live Updates Banner',
      'description': 'Live updates banner now supports manual swiping when multiple updates are active! Swipe left/right to instantly navigate between banners while automatic 4-second cycling continues. Auto-cycling intelligently pauses for 8 seconds when you manually scroll, then resumes seamlessly. Single banners work exactly as before.',
    },
    {
      'title': 'Additional Important Contacts',
      'description': 'Added two new contact numbers to the Important Contacts page.',
    },
    {
      'title': 'Google Calendar Event Deletion',
      'description': 'Resolved critical issue where deleting events from the app would not remove them from Google Calendar. Fixed timezone mismatch problem in event matching - events are now properly identified and deleted from Google Calendar when removed locally.',
    },
  ],
  '2.14.0': [
    {
      'title': 'Bus Tracking Integration',
      'description': 'Added real-time bus tracking feature with direct integration to bustimes.org! First, add your assigned bus number (EW132, PA155, etc.) to your shift, then track it on-the-go by tapping the location pin icon. Perfect for picking up buses mid-service - instantly see where your bus currently is.',
    },
    {
      'title': 'Driver-Friendly Workflow',
      'description': 'Simple 3-step process: check on bustimes.org for your bus, add the bus number to your shift in the app, then track it live when needed. Especially useful for afternoon shifts when picking up buses already in service.',
    },
    {
      'title': 'Compact UI Integration',
      'description': 'Bus tracking seamlessly integrated into existing event cards with compact icons and minimal spacing. Loading indicators show search progress. Clear error messages when buses aren\'t found - no unwanted browser windows opened for missing vehicles.',
    },
  ],
  '2.13.3': [
    {
      'title': 'Always-Visible Notes Icon with Smart Indicators',
      'description': 'Notes icon now appears on every event card for instant access! Visual indicators clearly show note status: filled icon with dot badge when notes exist, outlined muted icon when empty. No more hunting for the notes feature - it\'s always one tap away on any event.',
    },
    {
      'title': 'Improved Notes Discoverability & Design',
      'description': 'Consistent notes access across all event types including work shifts, spare duties, overtime, and holidays. Enhanced with theme-aware neutral colors that blend seamlessly with different shift backgrounds for a polished, professional appearance.',
    },
    {
      'title': 'Enhanced Notes Dialog Size',
      'description': 'Significantly expanded notes dialog for comfortable note-taking! Increased width to 90% of screen and height to 40% of screen, providing much more space for detailed shift notes. Text area now expands to fill available space with top-aligned input for better writing experience.',
    },
    {
      'title': 'Streamlined Settings Page Organization',
      'description': 'Complete reorganization of the Settings page for better user experience. Moved Feedback to App section from dropdown menu, relocated Live Updates Preferences to App section, and reordered sections for optimal flow: Appearance → App → Google Calendar → Backup & Restore → Notifications → Admin. Eliminated unnecessary section headers for cleaner navigation.',
    },
  ],
  '2.13.2': [
    {
      'title': 'Unused Code Elimination',
      'description': 'Removed unused fields, methods, and imports across update dialog components. Eliminated 4 code quality issues including unused _currentVersion fields and package_info_plus imports, improving code maintainability and reducing bundle size.',
    },
  ],
  '2.13.1': [
    {
      'title': 'Streamlined Update Dialog Experience',
      'description': 'Removed redundant "What\'s New" section from update dialogs that always showed generic placeholder text. Users will see the actual What\'s New screen after updating, making this section unnecessary. Update dialogs are now cleaner and more focused on the update action.',
    },
    {
      'title': 'Improved Update UI Flow',
      'description': 'Eliminated the confusing "Bug fixes and performance improvements / Check the What\'s New screen for detailed information" placeholder text. Update dialogs now show only essential information: version number and download options.',
    },
    {
      'title': 'Code Cleanup & Optimization',
      'description': 'Removed unused changelog parsing methods and imports from update dialogs, reducing code complexity and improving maintainability. Update dialog components are now more lightweight and efficient.',
    },
  ],
  '2.13.0': [
    {
      'title': 'Dark Mode Across Major Screens',
      'description': 'Fixed hardcoded colors throughout the app including Bills Screen, Statistics, Live Updates, Google Login, and Enhanced Update Dialog. Dark mode now works properly across all major features with excellent readability and visual consistency.',
    },
  ],
  '2.12.2': [
    {
      'title': 'Clickable Notes Icon',
      'description': 'Notes icon on event cards is now directly clickable! Tap the notes icon to instantly open the notes dialog for that event, eliminating the need to open the event details first. Provides faster, more intuitive access to your shift notes.',
    },
    {
      'title': 'Google Calendar Sharing Guide',
      'description': 'Added comprehensive help guide in Settings showing exactly how to share your work schedule with family and friends. Includes step-by-step instructions for calendar sharing, creating dedicated work calendars, and privacy options. Access via "How to Share Google Calendar" in Settings.',
    },
  ],
  '2.12.1': [
    {
      'title': 'FIXED: Live Updates Banner Layout Issues',
      'description': 'Resolved positioning problems with priority indicators (WARNING, CRITICAL, INFO) in the live updates banner. Text alignment is now consistent across all device sizes and screen orientations.',
    },
  ],
  '2.12.0': [
    {
      'title': 'NEW: Live Updates Banner System',
      'description': 'Introduced dynamic live updates banner that appears at the top of the calendar when admin posts important announcements. Real-time notifications keep all drivers informed of urgent updates, schedule changes, and important information.',
    },
    {
      'title': 'SECURITY: Production Password Protection',
      'description': 'Implemented secure admin password system using GitHub secrets. Admin password is no longer hardcoded and visible in the repository. Production builds use encrypted environment variables for maximum security.',
    },
    {
      'title': 'Polished Live Updates UI Experience',
      'description': 'Perfected banner behavior with smooth appearance/disappearance, consistent 80px height, and responsive design. Eliminated UI jumping and flashing when navigating calendar days/months for seamless user experience.',
    },
    {
      'title': 'Enhanced Environment Configuration',
      'description': 'Created AppConfig system for secure environment variable management. Development builds use fallback password while production leverages GitHub CI/CD secrets for deployment security.',
    },
    {
      'title': 'Improved Calendar Performance',
      'description': 'Optimized calendar rendering with better state management and reduced unnecessary rebuilds. Live updates integration now works seamlessly without impacting calendar interaction performance.',
    },
  ],
  '2.11.5': [
    {
      'title': 'FIXED: Holiday Display Issue',
      'description': 'Fixed critical issue where singular "Other" holidays appeared on both the correct day and the previous day. Holiday events now display only on the selected date as intended.',
    },
    {
      'title': 'Improved Date Range Logic',
      'description': 'Enhanced holiday date comparison logic to properly handle single-day holidays. Fixed inclusive date range checking that was incorrectly including adjacent dates.',
    },
    {
      'title': 'FIXED: Zone 4 Bogey Duties Board Parsing',
      'description': 'Fixed Zone 4 running boards parsing for bogey duties ending in "X" (e.g., PZ4/1X, PZ4/13X). These duties now correctly map to their corresponding board entries (1X→451, 13X→463) and display proper running board information when using the View Board feature.',
    },
    {
      'title': 'Enhanced Duty Number Conversion Logic',
      'description': 'Improved duty parsing algorithm to properly handle the Zone 4 numbering system where "X" represents 50 plus the base number. This ensures accurate board lookups for all Zone 4 duty types.',
    },
  ],
  '2.11.4': [
    {
      'title': 'FIXED: Last Week Statistics Date Range',
      'description': 'Fixed critical issue where "Last Week" statistics were not properly following the Sunday-to-Saturday week pattern. Overtime shifts (and other shifts) occurring on Sunday of the previous week now correctly appear when "Last Week" is selected.',
    },
    {
      'title': 'Consistent Week Calculations',
      'description': 'Synchronized "Last Week" calculation logic between Shift Type Statistics and Work Time Statistics. Both now use the same Sunday-to-Saturday week pattern ensuring accurate and consistent results across all statistics.',
    },
    {
      'title': 'Improved Date Range Accuracy',
      'description': 'Eliminated the issue where "Last Week" was calculated as "today minus 6 days" instead of the proper previous Sunday-to-Saturday week. Statistics now correctly match the established week boundaries used throughout the app.',
    },
    {
      'title': 'FIXED: Google Calendar Break Times',
      'description': 'Restored break times in Google Calendar event descriptions. Work shifts now properly include break time information (e.g., "Break Times: 13:30 - 14:00") when synced to Google Calendar. Improved reliability for rest day shifts to ensure both break times and "(Working on Rest Day)" indicator appear together when applicable.',
    },
    {
      'title': 'ENHANCED: Google Calendar Authentication',
      'description': 'Completely overhauled Google Calendar token management system with proactive refresh, persistent token tracking across app restarts, and intelligent startup validation. Eliminates timeout issues and manual re-authentication requirements. Tested and verified working in all scenarios including app closure and emulator environments.',
    },
    {
      'title': 'CODE CLEANUP: Production Ready',
      'description': 'Removed all debug print statements from Google Calendar service and helper functions. App now operates silently in production with clean console output and professional code standards.',
    },
  ],
  '2.11.3': [
    {
      'title': 'FIXED: Google Calendar Sync Issue',
      'description': 'Resolved critical issue where Google Calendar sync would fail silently due to BuildContext lifecycle problems. Events were detected as "missing" but sync would abort immediately without adding them to Google Calendar.',
    },
    {
      'title': 'Enhanced Sync Reliability',
      'description': 'Fixed BuildContext unmounted error that was stopping sync operations prematurely. Google Calendar sync now completes successfully even if the user navigates away from the sync dialog.',
    },
    {
      'title': 'Comprehensive Error Logging',
      'description': 'Added detailed logging throughout the Google Calendar sync pipeline to help diagnose issues. Authentication, connection testing, and event creation now provide clear feedback about success or failure reasons.',
    },
    {
      'title': 'Improved User Experience',
      'description': 'Eliminated the frustrating workflow where "Sync Missing Events" button would appear to work but events never actually appeared in Google Calendar. Sync operations are now robust and reliable.',
    },
    {
      'title': 'Better UI Feedback Control',
      'description': 'Added smart UI feedback system that prevents notification spam during bulk sync operations while still providing clear completion status and error messages when needed.',
    },
  ],
  '2.11.2': [
    {
      'title': 'EPIC Code Quality Achievement: 93.2% Complete!',
      'description': 'Massive improvement from 818 issues to just 56 issues! Advanced BuildContext async safety fixes preventing app crashes during navigation and async operations. Eliminated critical UI synchronization issues and improved error handling patterns.',
    },
    {
      'title': 'Enhanced App Stability & Crash Prevention',
      'description': 'Fixed BuildContext usage across async gaps in calendar operations, Google Calendar sync, and event management. Added proper mounted checks and context safety patterns to prevent widget disposal crashes.',
    },
    {
      'title': 'Continued Code Excellence Foundation',
      'description': 'Building on the revolutionary 91.9% achievement from v2.11.0, pushed code quality even higher to 93.2%. This establishes an exceptional foundation for rapid feature development and maximum app reliability.',
    },
    {
      'title': 'AsyncContext Safety Implementation',
      'description': 'Implemented proper async BuildContext patterns throughout calendar screen, event creation, and Google Calendar integration. These changes ensure stable app behavior during complex async workflows and prevent potential crashes.',
    },
  ],
  '2.11.1': [
    {
      'title': 'FIXED: Work Shift Event List Auto-Update',
      'description': 'Fixed critical issue where adding work shifts (PZ zones, Uni/Euro, Bus Check, Jamestown, etc.) required navigating to another day and back to see the new event in the list. Event cards now update immediately when work shifts are added using the proven refresh mechanism.',
    },
    {
      'title': 'Enhanced UI Synchronization',
      'description': 'Implemented consistent refresh trigger mechanism across all event types. Work shift addition now uses the same reliable UI update system as spare duty operations, ensuring immediate visibility of newly added events.',
    },
    {
      'title': 'Improved User Experience',
      'description': 'Eliminated the frustrating workflow interruption where users had to manually refresh the calendar view to see their newly added work shifts. All shift types now appear instantly in the event list upon creation.',
    },
  ],
  '2.11.0': [
    {
      'title': 'MASSIVE Code Quality Revolution: 91.9% Complete!',
      'description': 'Transformed code quality from 818 issues to just 66 issues! Fixed 752 code quality issues achieving 91.9% completion. This represents one of the largest code improvement initiatives in the app\'s history.',
    },
    {
      'title': 'Performance & Stability Mega-Fix',
      'description': 'CLEARED all 19 library_private_types_in_public_api issues, fixed 36+ BuildContext async gaps preventing crashes, eliminated 9 naming convention violations, and optimized 6 forEach performance bottlenecks.',
    },
    {
      'title': 'Exception Handling & String Optimization',
      'description': 'Fixed 6 exception handling issues using rethrow for better stack traces, eliminated 5 string interpolation inefficiencies, and removed unnecessary const keywords and getter/setter wrappers for cleaner code.',
    },
    {
      'title': 'Enhanced App Reliability',
      'description': 'Fixed BuildContext synchronization issues that could cause app crashes during navigation, improved error handling throughout the codebase, and established robust patterns for async operations.',
    },
    {
      'title': 'Constructor & Widget Optimizations',
      'description': 'Applied const optimizations to 4+ constructors improving render performance, fixed EdgeInsets declarations, and standardized widget creation patterns across the entire application.',
    },
    {
      'title': 'Developer Experience Improvements',
      'description': 'Implemented lowerCamelCase naming conventions, eliminated unnecessary code patterns, reduced cognitive complexity, and established consistent code style throughout the 50+ source files.',
    },
    {
      'title': 'Zero Breaking Changes Guarantee',
      'description': 'All 752 fixes completed with ZERO functional changes or visual modifications. Every feature works exactly as before while the underlying code is now significantly more maintainable and performant.',
    },
    {
      'title': 'Foundation for Future Development',
      'description': 'With 91.9% code quality, the app is now positioned for rapid feature development, easier maintenance, improved performance, and enhanced stability for all future updates.',
    },
  ],
  '2.10.1': [
    {
      'title': 'Enhanced Event Edit Dialog Layout',
      'description': 'Fixed inconsistent button layouts in event edit dialogs. View Board button (Zone 4 only) now appears in its own centered row, while Notes and Break Status buttons are consistently centered together for all event types.',
    },
    {
      'title': 'Premium View Board Button Design',
      'description': 'Transformed the View Board button into an attractive elevated button with custom styling. Features the app\'s primary color, white text/icon, rounded corners, subtle shadow, and a list icon to emphasize this special Zone 4 feature.',
    },
    {
      'title': 'Optimized Dialog Spacing',
      'description': 'Removed excessive spacing in event edit dialogs that was creating large gaps between action buttons and content sections. Dialogs now have more compact, visually pleasing layouts.',
    },
    {
      'title': 'Visual Polish & Consistency',
      'description': 'Improved overall visual consistency across event edit dialogs ensuring professional appearance and better user experience with standardized button spacing and alignment.',
    },
  ],
  '2.10.0': [
    {
      'title': 'NEW: Zone 4 Dublin Bus Running Boards Integration',
      'description': 'Revolutionary new feature! View detailed running board information for any Zone 4 duty by clicking "View Board" on event cards. Shows complete duty schedules across multiple buses with movements, handovers, and route information.',
    },
    {
      'title': 'Smart Day-Based Board Selection',
      'description': 'Automatically selects the correct running board file based on date: Zone4SunBoards.txt for Sundays and bank holidays, Zone4SatBoards.txt for Saturdays, and Zone4M-FBoards.txt for Monday-Friday operations.',
    },
    {
      'title': 'Beautiful Running Board Dialog Design',
      'description': 'Stunning card-based interface with numbered sections, color-coded movement icons (garage/SPL=orange, routes=green, locations=blue), gradient headers, and professional typography for maximum readability.',
    },
    {
      'title': 'Robust File Encoding Support',
      'description': 'Advanced encoding detection handles UTF-8, UTF-16 Little Endian, and UTF-16 Big Endian files with BOM detection. Automatically handles different file encodings from Dublin Bus systems ensuring reliable data loading.',
    },
    {
      'title': 'Intelligent Chronological Sorting',
      'description': 'Fixed duty 440 and other multi-section duties to display in proper chronological order (15:15 before 19:40) regardless of file order. Ensures logical schedule flow across different buses and routes.',
    },
    {
      'title': 'Comprehensive Duty Parsing Engine',
      'description': 'Sophisticated parsing system extracts duty information, movements, handovers, and transitions between buses. Handles both "starts" and "takes over" scenarios with accurate time and location tracking.',
    },
    {
      'title': 'Enhanced User Experience Refinements',
      'description': 'Simplified dialog title from "Running Board - Duty XXX" to "Duty XXX". Removed cluttered overview section. Added disclaimer: "Information on these boards may not be accurate. The boards files sometimes have errors. This View Boards feature is currently in testing."',
    },
    {
      'title': 'Professional Error Handling & Fallbacks',
      'description': 'Graceful handling of missing files, encoding issues, parsing errors, and malformed data. Clear error messages and fallback behaviors ensure app stability even with problematic source files.',
    },
  ],
  '2.9.1': [
    {
      'title': 'FIXED: Spare Duty Deletion UI Update',
      'description': 'Fixed critical issue where deleting spare duties required navigating to another day and back to see changes. Event cards now update immediately when duties are removed with improved state management for real-time UI synchronization.',
    },
    {
      'title': 'FIXED: Jamestown Statistics Integration',
      'description': 'Fixed Jamestown Road duties (811/xx shifts) not being properly included in statistics calculations. Jamestown shifts now contribute to work time totals, shift type breakdowns, and all statistical analysis with accurate data from JAMESTOWN_DUTIES.csv.',
    },
    {
      'title': 'FIXED: Google Calendar Authentication',
      'description': 'Eliminated need for manual sign-out/sign-in cycles with improved token management, multi-strategy authentication refresh, proactive validation, and robust error handling. Google Calendar sync now maintains reliable connection automatically.',
    },
  ],
  '2.9.0': [
    {
      'title': 'NEW: Jamestown Road Duties Support',
      'description': 'Complete integration of Jamestown Road duties (811/xx shifts)! Full Monday-Friday scheduling with dedicated CSV data, break times, location information, and route display. Jamestown shifts now available in zone dropdown.',
    },
    {
      'title': 'Route Information Display',
      'description': 'Added route information for Jamestown Road duties shown as "Routes: 70/X28" with route icon. Routes displayed below break times providing essential operational reference information.',
    },
    {
      'title': 'Enhanced Event Card Layout & Spacing',
      'description': 'Completely redesigned event card information hierarchy with optimized spacing between sections. Better visual separation between operational details and administrative information for improved readability.',
    },
    {
      'title': 'Standardized Font Weight Hierarchy',
      'description': 'Implemented consistent typography system: Bold titles, semi-bold time values (w600), medium operational details (w500), and normal administrative info (w400). Creates clear visual priority and professional appearance.',
    },
    {
      'title': 'Cleaner Text Formatting',
      'description': 'Removed colons from "Report:" and "Sign Off:" labels for cleaner, more natural text flow that better matches other information lines throughout the event cards.',
    },
    {
      'title': 'Consistent Break Times & Administrative Info',
      'description': 'Break times, routes, dates, bus assignments, and late break status now use consistent lighter font weight (w400) for proper information hierarchy, distinguishing operational details from reference information.',
    },
    {
      'title': 'Professional Information Architecture',
      'description': 'Restructured event cards with logical information flow: Title → Critical times → Location context → Operational details → Administrative reference. Creates intuitive, scannable interface for shift information.',
    },
  ],
  '2.8.58': [
    {
      'title': 'Fixed Bills Screen Row Alignment',
      'description': 'Resolved critical row misalignment in Bills screen between fixed shift column and scrollable data. All duties (including PZ1/97-100) now perfectly aligned with improved scroll synchronization and fixed row heights.',
    },
    {
      'title': 'Fixed Settings Page Layout',
      'description': 'Resolved Version History button being cut off by navigation bar on some devices. Added SafeArea wrapper and increased bottom padding to ensure all settings options are fully accessible.',
    },
    {
      'title': 'New Feature: Customizable Shift Colors',
      'description': 'Added ability to customize Early (E), Late (L), Middle (M), and Rest (R) shift colors in Appearance settings. Features intuitive color picker interface with real-time updates and reset option.',
    },
    {
      'title': 'Enhanced Backup System with Color Support',
      'description': 'Custom shift colors now included in manual and automatic backups. Color preferences are preserved when restoring from backup, ensuring personalized settings remain intact.',
    },
    {
      'title': 'Real-Time Color Updates',
      'description': 'Color changes now apply immediately throughout the app without requiring restart. Implemented callback system for instant UI updates across all screens when customizing shift colors.',
    },
  ],
  '2.8.57': [
    {
      'title': 'Enhanced Spare Duty System - Individual Bus Assignments',
      'description': 'Revolutionary upgrade to spare shift functionality! You can now assign individual buses to each spare duty. Add multiple duties (full duties, first half, second half) with dedicated bus assignments per duty.',
    },
    {
      'title': 'Smart Duty Type Restrictions',
      'description': 'Intelligent business logic prevents incompatible duty combinations: full duties block half duties, half duties block full duties. System guides you to logical assignments with contextual messaging.',
    },
    {
      'title': 'Improved Workout Duty Filtering',
      'description': 'Fixed workout duty logic: workouts now correctly excluded for half duties (first/second half) but allowed for full duties, matching operational requirements.',
    },
    {
      'title': 'Enhanced Spare Duty Bus Statistics',
      'description': 'Spare duty bus assignments now properly included in "Most Frequent Buses" statistics! All individual bus assignments from spare duties are tracked and counted alongside regular shifts.',
    },
    {
      'title': 'Professional Spare Shift Dialog Design',
      'description': 'Completely redesigned spare shift interface with modern cards, color-coded duty type buttons (Full=blue, First Half=orange, Second Half=teal), status indicators, and intuitive bus assignment workflow.',
    },
    {
      'title': 'Simplified Bus Assignment Button',
      'description': 'Streamlined bus assignment interface with clean "+" icon buttons. Replaced text-heavy "Assign/Change" buttons with compact, elegant blue "+" icons for a cleaner, more intuitive user experience.',
    },
    {
      'title': 'Aggregated Changelog System',
      'description': 'Revolutionary changelog experience! Users who miss multiple updates now see ALL missed versions in both update dialogs and What\'s New screen. No more missing important changes - complete update history displayed chronologically.',
    },
  ],
  '2.8.56': [
    {
      'title': 'Critical Layout Fixes - Navigation Bar & Content Issues',
      'description': 'Fixed major layout problems across multiple screens! Added SafeArea wrappers to prevent navigation bar from hiding content on What\'s New, Bills, and Pay Scale screens.',
    },
    {
      'title': 'What\'s New Screen Improvements',
      'description': 'Fixed RenderFlex overflow causing text cut-off and visual corruption. Long changelog titles now wrap properly instead of being truncated. Added responsive text handling.',
    },
    {
      'title': 'Bills Screen Data Visibility Enhancement',
      'description': 'Significantly increased column widths: shift column from 50px to 80px, data columns from 70px to 110px. Improved text wrapping prevents data from being cut off.',
    },
    {
      'title': 'Pay Scale Screen Bottom Content Access',
      'description': 'Added SafeArea wrapper to prevent bottom navigation from hiding pay scale content on devices with gesture navigation.',
    },
    {
      'title': 'Break Duration Display Added',
      'description': 'Event cards now show break duration in parentheses next to break times (e.g., "13:30 - 14:00 (30 mins)"). Automatically calculated from existing break time data.',
    },
    {
      'title': 'Google Calendar Access Information',
      'description': 'Added helpful disclaimers across Google Calendar screens explaining that test user approval is required. Users are directed to the feedback section to request access.',
    },
    {
      'title': 'Duty Information Disclaimer Added',
      'description': 'Added disclaimer in event creation dialog explaining that duty information comes from depot bills and may contain mistakes. Helps users understand data source and potential limitations.',
    },
    {
      'title': 'Dark Mode Disclaimer Added',
      'description': 'Added warning disclaimer to dark mode setting explaining that dark mode is not fully implemented yet and some dialogs/screens may not display correctly. Helps set proper user expectations.',
    },
    {
      'title': 'Fixed Update Dialog Information Accuracy',
      'description': 'Update dialogs now display correct changelog information instead of generic placeholder text. Removed misleading boilerplate from GitHub release notes.',
    },
    {
      'title': 'Fixed Rostered Sunday Pair Hours Calculation',
      'description': 'Sunday pair hours calculation now properly excludes overtime shifts, ensuring accurate 14h 30m overtime threshold calculations.',
    },
    {
      'title': 'Fixed Statistics Double-Counting Issue',
      'description': 'Critical fix: shifts spanning past midnight were being counted twice in statistics. Now properly handled with duplicate prevention across all statistics methods.',
    },
    {
      'title': 'Added Overtime Shifts Counter',
      'description': 'New "Overtime Shifts" statistic separately tracks OT shifts from regular shifts. Overtime shifts are now properly excluded from regular shift statistics.',
    },
    {
      'title': 'Fixed ID Handling Inconsistencies',
      'description': 'Resolved mismatch where duplicate checking looked for null values but stored empty strings. Standardized ID handling across all statistics methods.',
    },
    {
      'title': 'Enhanced User Experience',
      'description': 'Eliminated visual corruption, improved content readability, ensured all critical app data is fully accessible, and added helpful break duration information. These fixes address fundamental layout issues across the app.',
    },
  ],
  '2.8.55': [
    {
      'title': 'TARGET VERSION - Testing Instant Detection!',
      'description': 'This is the target update that v2.8.54 should detect INSTANTLY! If you\'re seeing this dialog immediately as the calendar screen loads (no delay), then instant automatic detection is WORKING PERFECTLY!',
    },
    {
      'title': 'Lightning Speed Validation Complete',
      'description': 'If this appeared instantly without any perceptible wait time, then we have achieved the ultimate update experience - immediate detection the moment the app loads!',
    },
    {
      'title': 'INSTANT UPDATE SYSTEM - MISSION ACCOMPLISHED!',
      'description': 'Instant detection + Smart Download = Revolutionary update experience! No more waiting, no more delays - just seamless, lightning-fast updates! The system is now perfect!',
    },
  ],
  '2.8.54': [
    {
      'title': 'INSTANT UPDATE DETECTION - Zero Delay Test!',
      'description': 'Testing INSTANT automatic update detection with NO delay! If you\'re seeing this dialog immediately as the calendar screen loads (within milliseconds), then instant detection is working perfectly!',
    },
    {
      'title': 'Lightning-Fast Response Validation',
      'description': 'Removed all delays - updates now appear instantly when the calendar screen is shown. This provides immediate notification the moment an update is available, making the experience truly seamless!',
    },
    {
      'title': 'INSTANT Revolutionary Update System!',
      'description': 'If this appeared instantly without any perceptible delay, both automatic detection AND instant timing are working flawlessly. The update experience is now truly instantaneous!',
    },
  ],
  '2.8.53': [
    {
      'title': 'TIMING TEST - Automatic Update Detection',
      'description': 'This is a test version to validate the 2-second automatic update detection timing. If you\'re seeing this dialog automatically without clicking anything, the rapid detection is working perfectly!',
    },
    {
      'title': 'Quick Response Validation',
      'description': 'Testing the optimized timing where updates appear within 2 seconds of app startup instead of the previous 10-second delay. This ensures immediate notification without being intrusive.',
    },
    {
      'title': 'REVOLUTIONARY UPDATE SYSTEM - Timing Perfect!',
      'description': 'If this appeared quickly and automatically, both automatic detection AND timing optimization are working flawlessly. The update experience is now truly seamless!',
    },
  ],
  '2.8.52': [
    {
      'title': 'REVOLUTIONARY UPDATE SYSTEM COMPLETE!',
      'description': 'Perfect automatic detection (2-second delay) + Smart Download with progress tracking! Transforms update experience from manual browser downloads to seamless app-store-like updates!',
    },
    {
      'title': 'Optimized User Experience',
      'description': 'Reduced automatic update check delay to 2 seconds for immediate notification. Removed debug messages for clean, polished experience. Updates appear quickly without interrupting initial app use.',
    },
    {
      'title': 'Mission Accomplished',
      'description': 'Both critical fixes working perfectly: forceCheck bypasses API limitations, Smart Download provides 80% of app store convenience while maintaining GitHub independence. Update adoption will skyrocket!',
    },
  ],
  '2.8.51': [
    {
      'title': 'SUCCESS! Automatic Detection is WORKING!',
      'description': 'If you\'re seeing this dialog automatically (without clicking anything), then our forceCheck fix WORKED! Automatic update detection is finally functioning perfectly!',
    },
    {
      'title': 'Final Smart Download Test',
      'description': 'Now test "Smart Download (Recommended)" to validate the complete revolutionary update system: automatic detection + in-app downloads with progress tracking!',
    },
    {
      'title': 'REVOLUTIONARY UPDATE SYSTEM COMPLETE!',
      'description': 'Both critical fixes are working: automatic detection bypasses frequency controls, and Smart Download provides app-store-like experience. Mission accomplished!',
    },
  ],
  '2.8.50': [
    {
      'title': 'FORCE CHECK FIX - Bypass Frequency Controls!',
      'description': 'Fixed automatic update detection by adding forceCheck: true to bypass frequency controls and API caching that was preventing automatic checks from finding available updates!',
    },
    {
      'title': 'Guaranteed Update Detection',
      'description': 'Automatic checks now use the same force parameters as manual checks, ensuring consistent behavior. This should solve the "random timing" issue where automatic checks missed updates!',
    },
    {
      'title': 'FINAL FIX TEST',
      'description': 'If this appears automatically when v2.8.48 restarts, our automatic detection is FINALLY working! Then test Smart Download to complete the revolutionary update system!',
    },
  ],
  '2.8.49': [
    {
      'title': 'TARGET UPDATE - Automatic Detection Test!',
      'description': 'This is the target update that v2.8.48 should automatically detect! If you\'re seeing this dialog automatically (without clicking anything), SUCCESS!',
    },
    {
      'title': 'Smart Download Final Validation',
      'description': 'Now test "Smart Download (Recommended)" to confirm it downloads in-app with progress instead of opening browser. This validates both fixes working together!',
    },
    {
      'title': 'REVOLUTIONARY UPDATE SYSTEM - FINAL TEST',
      'description': 'If both automatic detection AND Smart Download work, our transformation is complete: from manual browser downloads to seamless app-store-like updates!',
    },
  ],
  '2.8.48': [
    {
      'title': 'ENHANCED AUTO-DETECTION - Debug Mode!',
      'description': 'Improved automatic update detection with longer delays (10 seconds), retry attempts, and temporary debug messages. You should see snackbar messages indicating update check status!',
    },
    {
      'title': 'Extended Timing & Retries',
      'description': 'Automatic checks now wait 10 seconds for full app load, then retry after another 10 seconds if no update found. This should catch any timing issues.',
    },
    {
      'title': 'Debug Messages Added',
      'description': 'Temporary snackbar messages will show update check results so we can see what\'s happening without debug logs. This helps diagnose the detection issue!',
    },
  ],
  '2.8.47': [
    {
      'title': 'FINAL VALIDATION TEST - Success Confirmation!',
      'description': 'If you\'re seeing this dialog AUTOMATICALLY (without clicking anything), then automatic update detection is WORKING! This validates our CalendarScreen context fix is successful!',
    },
    {
      'title': 'Smart Download Final Test',
      'description': 'Now click "Smart Download (Recommended)" to test if it downloads in-app with progress tracking. If it works instead of opening browser, both fixes are COMPLETE!',
    },
    {
      'title': 'REVOLUTIONARY UPDATE SYSTEM VALIDATED',
      'description': 'This test confirms the complete transformation: automatic detection + in-app downloads. Your update experience is now seamless and app-store-like while maintaining GitHub independence!',
    },
  ],
  '2.8.46': [
    {
      'title': 'FINAL TEST - Automatic Update Detection Fixed!',
      'description': 'This should appear AUTOMATICALLY without clicking anything! We moved the update check to CalendarScreen with proper dialog context. If you\'re seeing this automatically, both fixes are COMPLETE!',
    },
    {
      'title': 'Context Fix Applied',
      'description': 'Moved automatic update detection from MyApp to CalendarScreen where the context is guaranteed to work for showing update dialogs. No more disposal issues!',
    },
    {
      'title': 'REVOLUTIONARY UPDATE SYSTEM COMPLETE',
      'description': 'Both automatic detection AND Smart Download now work perfectly. Your update experience is transformed from manual browser downloads to seamless in-app updates!',
    },
  ],
  '2.8.45': [
    {
      'title': 'TESTING THE CRITICAL FIXES!',
      'description': 'This is a test update to validate our critical fixes! If you\'re seeing this dialog automatically (without manually clicking), then automatic update detection is WORKING!',
    },
    {
      'title': 'Smart Download Validation Test',
      'description': 'Use "Smart Download (Recommended)" to test if it actually downloads in-app with permission requests and progress tracking, instead of opening the browser.',
    },
    {
      'title': 'What We Fixed in v2.8.44',
      'description': 'Fixed broken automatic updates (context disposal) and Smart Download permissions (always fell back to browser). This test validates both fixes work perfectly!',
    },
  ],
  '2.8.44': [
    {
      'title': 'CRITICAL FIXES: Update System Overhaul',
      'description': 'Fixed automatic update detection that was broken due to context disposal issues. Updates will now properly appear on app startup when available!',
    },
    {
      'title': 'Smart Download Permission Fix',
      'description': 'Fixed Smart Download immediately falling back to browser. Now properly requests storage and install permissions, with detailed progress tracking and error messages.',
    },
    {
      'title': 'Enhanced Error Handling',
      'description': 'Added comprehensive error handling with descriptive messages for download failures, permission issues, network timeouts, and installation problems.',
    },
    {
      'title': 'Improved Debugging',
      'description': 'Added detailed logging for troubleshooting update detection, permission requests, downloads, and installations. Better Android version detection.',
    },
  ],
  '2.8.43': [
    {
      'title': 'TESTING THE REVOLUTIONARY UPDATE SYSTEM',
      'description': 'This is a test update to demonstrate the new in-app APK download functionality! If you\'re seeing this, the smart download system is working perfectly.',
    },
    {
      'title': 'New Update Experience Validation',
      'description': 'Testing real-time progress tracking, automatic installation, and the beautiful new update dialog. This validates the complete transformation from browser-based to in-app updates.',
    },
  ],
  '2.8.42': [
    {
      'title': 'REVOLUTIONARY IN-APP UPDATE EXPERIENCE',
      'description': 'Introducing smart APK downloads! No more switching to browser and navigating through folders. Updates now download directly in-app with real-time progress tracking and automatic installation.',
    },
    {
      'title': 'Enhanced Update Dialog',
      'description': 'Beautiful new update dialog with two options: "Smart Download (Recommended)" for seamless in-app updates, or "Browser Download" for traditional method. Shows download progress with MB transferred and percentage completion.',
    },
    {
      'title': 'Streamlined User Experience',
      'description': 'Transforms update flow from: App → Browser → Downloads folder → Manual install, to simply: App → Download → Install → Done. Significantly improves update adoption rates.',
    },
    {
      'title': 'Technical Infrastructure',
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
