# Spare Driver Calendar

**Known Issues**
- Notifications are broken

A specialized Flutter application designed for spare drivers to manage their shift patterns, work schedules, and important events. This app helps drivers who work on rotating shift patterns to track their work schedule alongside personal events.

## Features

- **Shift Pattern Management**
  - Configure your unique rest day pattern
  - Automatic calculation of rotating shift schedules
  - Visual representation of upcoming shifts

- **Zone Types Support**
  - Supports different Zones (Spare, Uni/Euros)
  - Zone-specific duty tracking
  - Zone 3 boards integration (Currently disabled, with more zones coming soon)

- **Work Shift Tracking**
  - Log work shifts with specific details
  - Track zone, shift number, start/end times
  - Break duration tracking
  - Current bill information integration

- **Google Calendar Integration** ⭐ **Recently Improved**
  - Seamless synchronization with Google Calendar using reliable `google_sign_in` package
  - Access schedule from any device
  - Receive reminders
  - Share availability with others
  - Improved CI/CD compatibility for automated builds
  - Better error handling and authentication flow

- **Dark Mode Support**
  - Comfortable viewing in any lighting conditions
  - Light and dark theme options
  - Battery-efficient dark mode

- **Statistics**
  - Comprehensive work pattern insights
  - Shift type frequency tracking
  - Work-rest balance analysis
  - Schedule trend identification

- **Holiday Tracking**
  - Track given holidays
  - Manage personal holidays
  - Integrated holiday schedule organization

- **Bus Tracking**
  - Log buses driven
  - Maintain bus history for reference

- **Feedback**
  - Submit suggestions, bug reports, or general feedback directly via the app menu.

## Google Calendar Setup

For Google Calendar integration to work properly, you'll need to configure Google Cloud Console. See the detailed setup guide:

📋 **[Google Calendar Setup Guide](GOOGLE_CALENDAR_SETUP_GUIDE.md)**

The guide covers:
- Google Cloud Console configuration
- OAuth setup for Android
- CI/CD integration
- Troubleshooting common issues

## Downloading the Application (APK for Android)
If you prefer not to build the app yourself, you can download the pre-compiled Android application package (.apk) directly from the project's releases page and install it on your Android device.
 * Navigate to Releases: Open a web browser on your Android device and go to the Spare Driver Calendar GitHub Releases page:
   https://github.com/robertf670/spdrivercalendar/releases
 * Find the Latest Release: Look for the release tagged as "Latest". If there isn't one, choose the topmost release (which is usually the newest).
 * Locate the APK File: Scroll down to the Assets section for that release. Find the file that ends with .apk (e.g., app-release.apk or spdrivercalendar-vX.Y.Z.apk).
 * Download the APK: Tap on the .apk file name to download it to your device. Your browser might warn you about downloading APK files; proceed if you trust the source.
 * Install the APK:
   * Once downloaded, open your device's Files or Downloads app.
   * Tap on the downloaded .apk file.
   * You might be prompted to allow installation from unknown sources. You need to enable this setting (usually in your device's Security settings) to install APKs from outside the Google Play Store. Be aware of the security implications of enabling this setting.
   * Follow the on-screen prompts to install the application.
   * After installation, you can find the "Spare Driver Calendar" app in your app drawer.
Note: Check the GitHub Releases page periodically for updates.

**Important for Google Calendar**: If you download a pre-built APK, the Google Calendar features may not work immediately. This is because Google OAuth requires specific SHA-1 fingerprints to be configured. Contact the developer or set up your own Google Cloud Console project following the setup guide.
   
## Usage

1. **Initial Setup**
   - Set your rest days pattern when first using the app
   - Configure your shift pattern preferences

2. **Adding Work Shifts**
   - Tap the + button to add work shifts
   - Select your zone and shift number
   - Add specific details as needed

3. **Managing Spare Duties**
   - Add duties on spare shifts by tapping the event
   - Update or modify as needed

4. **Google Calendar Integration**
   - Connect to Google Calendar in Settings
   - Sync your shifts across devices
   - The app will guide you through the sign-in process
   - Ensure you're added as a test user if the app is in testing mode

5. **Viewing Statistics**
   - Access work patterns and time tracking
   - Analyze your schedule in the Statistics screen

6. **Holiday Management**
   - Add given holidays through the Holidays menu
   - Track personal holidays
   - View your complete holiday schedule

7. **Board Access**
   - View Zone 3 boards (Note: This feature is currently disabled).
   - Access detailed shift information
   - Plan routes effectively

8. **Submit Feedback**
   - Use the "Feedback" option in the app menu to send feedback to the developer.

## Building from Source

### Prerequisites
- Flutter SDK (latest stable version)
- Android development environment
- Google Cloud Console project (for Google Calendar features)

### Setup
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Google Calendar integration (see setup guide)
4. Build the app: `flutter build apk --release`

### Development Notes
- The app uses `google_sign_in` package for reliable Google authentication
- CI/CD is configured with GitHub Actions
- Supports both debug and release builds with proper keystore management

## Support

For support or questions, please contact ixrqq@tuta.io

For Google Calendar setup issues, please refer to the [setup guide](GOOGLE_CALENDAR_SETUP_GUIDE.md) first.
