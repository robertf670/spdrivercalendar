import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/core/mixins/text_rendering_mixin.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  AboutScreenState createState() => AboutScreenState();
}

class AboutScreenState extends State<AboutScreen> with TextRenderingMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones) - Balanced sizing
    if (screenWidth < 350) {
      return {
        'padding': 12.0,              // Reasonable padding
        'cardPadding': 14.0,          // Balanced card padding
        'spacing': 16.0,              // Reasonable spacing
        'smallSpacing': 12.0,         // Smaller spacing
        'crossAxisCount': 2,          // 2 columns on small screens
        'iconSize': 24.0,             // Readable icons
        'headerIconSize': 18.0,       // Header icons
        'avatarRadius': 32.0,         // Smaller avatar
        'avatarSize': 64.0,           // Smaller avatar image
        'gridSpacing': 8.0,           // Tighter grid spacing
        'featureCardPadding': 6.0,     // Minimal padding for compact cards
        'featureCardFontSize': 12.0,   // Larger, more readable font
        'categoryTitleFontSize': 15.0, // Category titles
        'featureTitleFontSize': 13.0,   // Feature item titles
        'featureDescFontSize': 12.0,    // Feature descriptions
        'childAspectRatio': 1.2,       // Taller, narrower cards
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'padding': 14.0,
        'cardPadding': 16.0,
        'spacing': 18.0,
        'smallSpacing': 14.0,
        'crossAxisCount': 2,
        'iconSize': 26.0,
        'headerIconSize': 19.0,
        'avatarRadius': 36.0,
        'avatarSize': 72.0,
        'gridSpacing': 9.0,
        'featureCardPadding': 7.0,
        'featureCardFontSize': 12.0,
        'categoryTitleFontSize': 15.5,
        'featureTitleFontSize': 13.5,
        'featureDescFontSize': 12.5,
        'childAspectRatio': 1.15,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'padding': 15.0,
        'cardPadding': 18.0,
        'spacing': 20.0,
        'smallSpacing': 15.0,
        'crossAxisCount': 2,
        'iconSize': 26.0,
        'headerIconSize': 20.0,
        'avatarRadius': 38.0,
        'avatarSize': 76.0,
        'gridSpacing': 12.0,
        'featureCardPadding': 10.0,
        'featureCardFontSize': 12.0,
        'categoryTitleFontSize': 16.0,
        'featureTitleFontSize': 14.0,
        'featureDescFontSize': 13.0,
        'childAspectRatio': 1.0,
      };
    }
    // Regular phones
    else if (screenWidth < 600) {
      return {
        'padding': 16.0,              // Original size
        'cardPadding': 20.0,
        'spacing': 22.0,
        'smallSpacing': 16.0,
        'crossAxisCount': 2,
        'iconSize': 28.0,             // Original size
        'headerIconSize': 20.0,       // Original size
        'avatarRadius': 40.0,         // Original size
        'avatarSize': 80.0,           // Original size
        'gridSpacing': 12.0,          // Original size
        'featureCardPadding': 12.0,    // Original size
        'featureCardFontSize': 12.0,
        'categoryTitleFontSize': 16.0,
        'featureTitleFontSize': 14.0,
        'featureDescFontSize': 13.0,
        'childAspectRatio': 1.0,
      };
    }
    // Tablets
    else if (screenWidth < 900) {
      return {
        'padding': 16.0,
        'cardPadding': 22.0,
        'spacing': 24.0,
        'smallSpacing': 16.0,
        'crossAxisCount': 3,          // 3 columns on tablets
        'iconSize': 28.0,
        'headerIconSize': 20.0,
        'avatarRadius': 40.0,
        'avatarSize': 80.0,
        'gridSpacing': 12.0,
        'featureCardPadding': 12.0,
        'featureCardFontSize': 12.0,
        'categoryTitleFontSize': 16.0,
        'featureTitleFontSize': 14.0,
        'featureDescFontSize': 13.0,
        'childAspectRatio': 1.0,
      };
    }
    // Large tablets/desktop
    else {
      return {
        'padding': 16.0,              // Original size
        'cardPadding': 24.0,          // Original size
        'spacing': 24.0,              // Original size
        'smallSpacing': 16.0,         // Original size
        'crossAxisCount': 3,          // Original size
        'iconSize': 28.0,             // Original size
        'headerIconSize': 20.0,       // Original size
        'avatarRadius': 40.0,         // Original size
        'avatarSize': 80.0,           // Original size
        'gridSpacing': 12.0,          // Original size
        'featureCardPadding': 12.0,    // Original size
        'featureCardFontSize': 12.0,
        'categoryTitleFontSize': 16.0,
        'featureTitleFontSize': 14.0,
        'featureDescFontSize': 13.0,
        'childAspectRatio': 1.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        elevation: 0,
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(3),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(sizes['padding']!),
          child: Column(
                children: [
            // App Header
            _buildAppHeader(sizes),
            SizedBox(height: sizes['spacing']!),
            
            // Description
            _buildDescriptionCard(sizes),
            SizedBox(height: sizes['spacing']!),
            
            // Key Features Overview
            _buildFeaturesOverview(sizes),
            SizedBox(height: sizes['spacing']!),
            
            // Detailed Features
            _buildDetailedFeatures(sizes),
                  SizedBox(height: sizes['smallSpacing']!),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildAppHeader(Map<String, double> sizes) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizes['cardPadding']!),
        child: Column(
          children: [
                  CircleAvatar(
              radius: sizes['avatarRadius']!,
                    backgroundColor: Colors.transparent,
                    child: Image.asset(
                'assets/appiconwhitebg.png',
                width: sizes['avatarSize']!,
                height: sizes['avatarSize']!,
                    ),
                  ),
                  SizedBox(height: sizes['smallSpacing']!),
                  Text(
                    AppConstants.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
            SizedBox(height: sizes['padding']! * 0.5),
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

  Widget _buildDescriptionCard(Map<String, double> sizes) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizes['cardPadding']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: sizes['headerIconSize']!,
                ),
                SizedBox(width: sizes['padding']! * 0.5),
            Text(
                  'About This App',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: sizes['smallSpacing']!),
            const Text(
              'Spare Driver Calendar is a comprehensive shift management solution designed specifically for public transport drivers. More than just a calendar, it\'s your complete toolkit for managing rotating shift patterns, staying informed with real-time updates, and accessing essential driver resources.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: sizes['padding']! * 0.75),
            const Text(
              'Built with deep understanding of driver workflows, the app seamlessly integrates shift scheduling, running board information, communication systems, and productivity tools into one powerful platform.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: sizes['smallSpacing']!),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesOverview(Map<String, double> sizes) {
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
        SizedBox(height: sizes['smallSpacing']!),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: sizes['crossAxisCount']!.toInt(),
            crossAxisSpacing: sizes['gridSpacing']!,
            mainAxisSpacing: sizes['gridSpacing']!,
            childAspectRatio: sizes['childAspectRatio']!,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return _buildFeatureOverviewCard(
              feature['icon'] as IconData,
              feature['title'] as String,
              feature['color'] as Color,
              sizes,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureOverviewCard(IconData icon, String title, Color color, Map<String, double> sizes) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizes['featureCardPadding']!),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: sizes['iconSize']!,
              color: color,
            ),
            SizedBox(height: 4.0),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: sizes['featureCardFontSize']!,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedFeatures(Map<String, double> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sizes['smallSpacing']!),
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
          sizes,
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
          sizes,
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
          sizes,
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
          sizes,
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
          sizes,
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
          sizes,
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
          sizes,
        ),
      ],
    );
  }

  Widget _buildFeatureCategory(String title, IconData icon, Color color, List<Map<String, String>> features, Map<String, double> sizes) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: sizes['smallSpacing']!),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizes['smallSpacing']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: sizes['headerIconSize']!,
                ),
                SizedBox(width: sizes['padding']! * 0.5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: sizes['categoryTitleFontSize']!,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: sizes['padding']! * 0.75),
            ...features.map((feature) => _buildFeatureItem(
              feature['title']!,
              feature['description']!,
              sizes,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, Map<String, double> sizes) {
    return Padding(
      padding: EdgeInsets.only(bottom: sizes['padding']! * 0.75),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppTheme.successColor, size: sizes['headerIconSize']! * 0.9),
          SizedBox(width: sizes['padding']! * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: sizes['featureTitleFontSize']!,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: sizes['featureDescFontSize']!,
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
