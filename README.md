# Spare Driver Calendar

**Known Issues**
- Notifications are broken
- Notes seem to not be saving
- Sunday Early/Late 14hr30m comparison broken

A specialized Flutter application designed for spare drivers to manage their shift patterns, work schedules, and important events. This app helps drivers who work on rotating shift patterns to track their work schedule alongside personal events.

## Features

- **Shift Pattern Management**
  - Configure your unique rest day pattern
  - Automatic calculation of rotating shift schedules
  - Visual representation of upcoming shifts

- **Zone Types Support**
  - Supports different Zones (Spare, Uni/Euros)
  - Zone-specific duty tracking
  - Zone 3 boards integration (with more zones coming soon)

- **Work Shift Tracking**
  - Log work shifts with specific details
  - Track zone, shift number, start/end times
  - Break duration tracking
  - Current bill information integration

- **Google Calendar Integration**
  - Seamless synchronization with Google Calendar
  - Access schedule from any device
  - Receive reminders
  - Share availability with others

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

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/robertf670/spdrivercalendar.git
   ```

2. Navigate to the project directory:
   ```bash
   cd spdrivercalendar
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

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

5. **Viewing Statistics**
   - Access work patterns and time tracking
   - Analyze your schedule in the Statistics screen

6. **Holiday Management**
   - Add given holidays through the Holidays menu
   - Track personal holidays
   - View your complete holiday schedule

7. **Board Access**
   - View Zone 3 boards (more zones coming soon)
   - Access detailed shift information
   - Plan routes effectively

## Support

For support or questions, please contact the repository owner.
