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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
            // App Header
            _buildAppHeader(),
            const SizedBox(height: 24),
            
            // Description
            _buildDescriptionCard(),
            const SizedBox(height: 24),
            
            // Key Features Overview
            _buildFeaturesOverview(),
            const SizedBox(height: 24),
            
            // Detailed Features
            _buildDetailedFeatures(),
                  const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
                  CircleAvatar(
              radius: 40,
                    backgroundColor: Colors.transparent,
                    child: Image.asset(
                'assets/appiconwhitebg.png',
                width: 80,
                height: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
            const SizedBox(height: 8),
            Text(
              'Your comprehensive shift management toolkit',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
              ),
            ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
            Text(
                  'About This App',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Spare Driver Calendar is a comprehensive shift management solution designed specifically for public transport drivers. More than just a calendar, it\'s your complete toolkit for managing rotating shift patterns, staying informed with real-time updates, and accessing essential driver resources.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Built with deep understanding of driver workflows, the app seamlessly integrates shift scheduling, running board information, communication systems, and productivity tools into one powerful platform.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesOverview() {
    final features = [
      {
        'icon': Icons.notifications_active,
        'title': 'Live Updates',
        'color': Colors.orange,
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Smart Scheduling',
        'color': Colors.blue,
      },
      {
        'icon': Icons.location_on,
        'title': 'Bus Tracking',
        'color': Colors.green,
      },
      {
        'icon': Icons.sync,
        'title': 'Google Sync',
        'color': Colors.purple,
      },
      {
        'icon': Icons.analytics,
        'title': 'Analytics',
        'color': Colors.teal,
      },
      {
        'icon': Icons.palette,
        'title': 'Customization',
        'color': Colors.pink,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return _buildFeatureOverviewCard(
              feature['icon'] as IconData,
              feature['title'] as String,
              feature['color'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureOverviewCard(IconData icon, String title, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCategory(
          'Communication & Updates',
          Icons.campaign,
          Colors.orange,
          [
            {
              'title': 'Live Updates Banner',
              'description': 'Stay informed with real-time announcements, service updates, and important notices. Critical information appears instantly at the top of your calendar with priority indicators for different urgency levels.'
            },
          ],
        ),
        _buildFeatureCategory(
          'Shift Management',
          Icons.schedule,
          Colors.blue,
          [
            {
              'title': 'Intelligent Shift Patterns',
              'description': 'Configure your unique rest day pattern and the app automatically calculates your entire rotating shift schedule. Visualize upcoming shifts weeks in advance with accurate pattern prediction.'
            },
            {
              'title': 'Comprehensive Shift Tracking',
              'description': 'Log work shifts with detailed information including zone assignments, shift numbers, precise start and end times, break durations, and bus assignments. All integrated with current depot bill information.'
            },
            {
              'title': 'Zone Support',
              'description': 'Full support for all zone types including Zone 1-4, Spare duties, and Uni/Euro routes. Each zone type handled with appropriate scheduling and tracking capabilities.'
            },
          ],
        ),
        _buildFeatureCategory(
          'Running Boards & Operations',
          Icons.directions_bus,
          Colors.green,
          [
            {
              'title': 'Zone 4 Running Boards',
              'description': 'Access detailed running board information for Zone 4 duties. View complete duty schedules across multiple buses, including movements, handovers, route transitions, and operational timing. Automatically selects correct board files based on day type.'
            },
            {
              'title': 'Smart Board Navigation',
              'description': 'Advanced chronological sorting ensures duty information displays in proper time order. Handles complex multi-section duties with accurate progression across different routes and locations.'
            },
          ],
        ),
        _buildFeatureCategory(
          'Driver Resources',
          Icons.work,
          Colors.purple,
          [
            {
              'title': 'Pay Scales & Rates',
              'description': 'Access comprehensive pay scale information with rates for different years of service and payment types. Essential reference for understanding compensation structure.'
            },
            
            {
              'title': 'Real-Time Bus Tracking',
              'description': 'Track your assigned buses in real-time with direct integration to bustimes.org. Add your bus number to your shift, then tap the location icon to see where it currently is. Perfect for picking up buses mid-service during afternoon shifts.'
            },
            {
              'title': 'Vehicle Assignment Tracking',
              'description': 'Record and track the buses you\'ve driven. Maintain a complete log for reference, reporting, or personal records.'
            },
                         {
               'title': 'Important Contacts',
               'description': 'Quick access to essential phone numbers and contact information for depot and controllers.'
             },
          ],
        ),
        _buildFeatureCategory(
          'Integration & Synchronization',
          Icons.sync,
          Colors.teal,
          [
            {
              'title': 'Google Calendar Sync',
              'description': 'Seamlessly synchronize your work shifts with Google Calendar. Access your schedule from any device, receive automatic reminders, and share your availability with family or friends.'
            },
            {
              'title': 'Intelligent Backup System',
              'description': 'Automatic and manual backup options protect your data. Custom preferences, shift colors, and settings are preserved when restoring from backup across devices.'
            },
            {
              'title': 'Smart Updates',
              'description': 'In-app update system with real-time progress tracking and automatic installation. No need to switch to browser or navigate through download folders.'
            },
          ],
        ),
        _buildFeatureCategory(
          'Analytics & Insights',
          Icons.analytics,
          Colors.indigo,
          [
            {
              'title': 'Work Pattern Analytics',
              'description': 'Comprehensive statistics showing shift frequency patterns, work-rest balance analysis, and trend identification. Track overtime shifts separately from regular duties.'
            },
                         {
               'title': 'Time Tracking',
               'description': 'Detailed work time calculations with proper handling of shifts spanning midnight and rostered hour tracking.'
             },
            {
              'title': 'Holiday Management',
              'description': 'Organize both allocated holidays and personal time off. Integrated holiday tracking ensures complete schedule visibility and prevents scheduling conflicts.'
            },
          ],
        ),
        _buildFeatureCategory(
          'Customization & Productivity',
          Icons.palette,
          Colors.pink,
          [
            {
              'title': 'Custom Shift Colors',
              'description': 'Personalize your calendar with custom colors for Early, Late, Middle, and Rest shifts. Intuitive color picker with real-time preview and instant updates across the entire app.'
            },
            {
              'title': 'Event Notes & Reminders',
              'description': 'Add detailed notes or reminders to any shift or event. Access notes directly from event cards with full editing capabilities for important information storage.'
            },
            {
              'title': 'Dark Mode Support',
              'description': 'Comfortable viewing in any lighting condition with full dark theme support. Reduces eye strain during night shifts and conserves battery life on mobile devices.'
            },
            {
              'title': 'Feedback Integration',
              'description': 'Direct feedback channel for suggestions, bug reports, or feature requests. Your input drives continuous improvement and feature development.'
            },
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCategory(String title, IconData icon, Color color, List<Map<String, String>> features) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => _buildFeatureItem(
              feature['title']!,
              feature['description']!,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
