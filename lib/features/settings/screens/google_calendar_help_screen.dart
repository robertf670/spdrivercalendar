import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class GoogleCalendarHelpScreen extends StatelessWidget {
  const GoogleCalendarHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Sharing Guide'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction Card
            _buildIntroCard(context),
            const SizedBox(height: 16),
            
            // Step 1: Setup Sync
            _buildStepCard(
              context,
              '1',
              'Set Up Calendar Sync',
              'First, make sure your work shifts are syncing to Google Calendar',
              [
                'Enable "Sync with Google Calendar" in settings',
                'Your shifts will appear in your main Google Calendar',
                'Events like "PZ4/01", "SP0600", will be created',
              ],
              Icons.sync,
              AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            
            // Step 2: Share Calendar
            _buildStepCard(
              context,
              '2',
              'Share Your Calendar',
              'Choose the best sharing method for your family',
              [
                'Open Google Calendar app or calendar.google.com',
                'Tap the 3 lines menu → Settings',
                'Find your main calendar (usually your email name)',
                'Tap "Share with specific people"',
                'Add family/friends email addresses',
                'Choose "See only free/busy" OR "See all event details"',
              ],
              Icons.share,
              Colors.green,
            ),
            const SizedBox(height: 16),
            
            // Step 3: Alternative Method
            _buildStepCard(
              context,
              '3',
              'Create Dedicated Work Calendar (Recommended)',
              'Better organization by separating work and personal events',
              [
                'In Google Calendar, tap "+" next to "Other calendars"',
                'Select "Create new calendar"',
                'Name it "Work Shifts" or "Driver Schedule"',
                'Choose a color (blue or green works well)',
                'Share this new calendar with family/friends',
                'Your personal events stay private!',
              ],
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            
            // What Family Sees
            _buildWhatTheySeeDock(context),
            const SizedBox(height: 16),
            
            // Tips Section
            _buildTipsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share Your Work Schedule',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'After syncing your shifts to Google Calendar, you can easily share your work schedule with family and friends. This helps them know when you\'re working and when you\'re available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    String stepNumber,
    String title,
    String description,
    List<String> steps,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      stepNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatTheySeeDock(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'What Family & Friends Will See',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your shared calendar will show your work shifts clearly:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildExampleShift(context, 'PZ4/01', '06:00 - 14:00', 'Monday', Colors.red),
            _buildExampleShift(context, 'SP0730', '07:30 - 15:30', 'Tuesday', Colors.orange),
            _buildExampleShift(context, 'Rest Day', 'All day', 'Wednesday', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleShift(BuildContext context, String title, String time, String day, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day: $title',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pro Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip(context, '📱', 'Family can add your calendar to their phones for quick access'),
            _buildTip(context, '🔔', 'They can set their own reminders for your shifts if needed'),
            _buildTip(context, '🚫', 'You can revoke sharing access anytime from Google Calendar settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
} 