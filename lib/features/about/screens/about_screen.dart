import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/core/mixins/text_rendering_mixin.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  AboutScreenState createState() => AboutScreenState();
}

class AboutScreenState extends State<AboutScreen> with TextRenderingMixin {
  @override

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: Image.asset(
                      'assets/appiconwhitebg.png', // Path to your app icon
                      width: 60,
                      height: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildInfoSection('App Description', _buildDescriptionContent()),
                  _buildInfoSection('Features', _buildFeaturesContent()),
                  _buildInfoSection('How to Use', _buildHowToUseContent()),
                  // Removed the Support section
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionContent() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spare Driver Calendar is a specialized calendar application designed for spare drivers to manage their shift patterns, work schedules, and important events.',
        ),
        SizedBox(height: 8),
        Text(
          'The app is built specifically for drivers who work on rotating shift patterns and need to track their work schedule alongside personal events.',
        ),
      ],
    );
  }

  Widget _buildFeaturesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem('Shift Pattern Management',
            'Configure your unique rest day pattern, and the app will automatically calculate your entire rotating shift schedule. Easily visualize your upcoming shifts and plan accordingly.'),
        _buildFeatureItem('Zone Types',
            'The app supports the different Zones, Spare, and Uni/Euros.'),
        _buildFeatureItem('Work Shift Tracking',
            'Log your work shifts with specific details such as zone, shift number, start and end times, and break durations. This uses current bill information provided in the depot.'),
        _buildFeatureItem('Google Calendar Integration',
            'Seamlessly synchronize your work shifts with your Google Calendar. Access your schedule from any device, receive reminders, and share your availability with others.'),
        _buildFeatureItem('Dark Mode Support',
            'Enjoy a comfortable viewing experience in any lighting conditions with the option to switch between light and dark themes. Dark mode reduces eye strain and conserves battery life.'),
        _buildFeatureItem('Statistics',
            'Gain insights into your work patterns with comprehensive statistics. Track the frequency of different shift types, analyze your work-rest balance, and identify trends in your schedule.'),
        _buildFeatureItem('Holiday Tracking',
            'Add and track your given holidays, and any personal holidays alongside your shifts. Keep your holiday schedule organized in one place.'),
        _buildFeatureItem('Boards',
            'Access Zone 3 boards. (Note: This feature is currently disabled). View detailed shift information and plan your routes effectively.'),
        _buildFeatureItem('Bus Tracking',
            'Add the bus you drove, keep track of buses driven in case you need to note them.'),
        _buildFeatureItem('Event Notes',
            'Add specific notes or reminders to any shift or event directly via the event card.'),
        _buildFeatureItem('Contacts Page',
            'Store and quickly access important phone numbers and contact details.'),
        _buildFeatureItem('Feedback',
            'Share your suggestions, report bugs, or provide general feedback directly through the app menu to help improve the application.'),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHowToItem('1. Initial Setup',
            'Set your rest days pattern when first using the app. This configures your shift pattern.'),
        _buildHowToItem('2. Add Work Shifts',
            'Tap the + button to add work shifts. Select your zone and shift number.'),
        _buildHowToItem('3. Spare Duties',
            'If you receive a duty on a spare shift, you can add it by tapping the event.'),
        _buildHowToItem('4. Google Calendar',
            'Connect to Google Calendar in Settings to sync your shifts across devices.'),
        _buildHowToItem('5. View Statistics',
            'Check your work patterns and work time in the Statistics screen.'),
        _buildHowToItem('6. Add Holidays',
            'Add your given holidays, and any personal holidays through the Holidays menu to keep track of your time off.'),
        _buildHowToItem('7. View Boards',
            'Access Zone 3 boards by clicking on a Zone 3 duty in your event list. (Note: This feature is currently disabled).'),
        _buildHowToItem('8. Customize',
            'Adjust app settings including dark mode in the Settings screen.'),
        _buildHowToItem('9. Add Notes',
            'Tap an event card and use the "Notes" button to view or edit notes for that specific event.'),
        _buildHowToItem('10. Use Contacts',
            'Access the Contacts page from the side menu to manage your important numbers.'),
        _buildHowToItem('11. Submit Feedback',
            'Use the "Feedback" option in the top-right menu to send your thoughts or report issues directly to the developer.'),
      ],
    );
  }

  Widget _buildHowToItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(description),
        ],
      ),
    );
  }
}
