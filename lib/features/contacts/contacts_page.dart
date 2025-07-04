import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:spdrivercalendar/theme/app_theme.dart'; // Import AppTheme for styling

class ContactsPage extends StatelessWidget {
  const ContactsPage({Key? key}) : super(key: key);

  // Helper function to launch phone calls
  Future<void> _launchPhoneCall(String phoneNumber, BuildContext context) async {
    // Capture ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Remove spaces and non-digit characters for the tel: URI
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'\s+'), ''));
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Show error if the phone app can't be launched
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call to $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Catch any other errors during launch
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error launching phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important Contacts'),
        elevation: 1, // Add slight elevation
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // Add padding around the list
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.business, color: AppTheme.primaryColor),
              ),
              title: const Text(
                'Phibsboro Depot',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('01 703 3462'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                tooltip: 'Call Phibsboro Depot',
                onPressed: () => _launchPhoneCall('017033462', context),
              ),
              onTap: () => _launchPhoneCall('017033462', context), // Allow tapping anywhere on the tile
            ),
          ),
          // Add more contacts here using the same Card/ListTile structure
          const SizedBox(height: 8), // Spacer between cards
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.inventory_2_outlined, color: AppTheme.secondaryColor), // Icon for lost property
              ),
              title: const Text(
                'Lost Property',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('01 703 1321'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                tooltip: 'Call Lost Property',
                onPressed: () => _launchPhoneCall('017031321', context),
              ),
              onTap: () => _launchPhoneCall('017031321', context),
            ),
          ),
          const SizedBox(height: 8), // Spacer between cards
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                child: const Icon(Icons.admin_panel_settings, color: Colors.orange), // Icon for clerical office
              ),
              title: const Text(
                'Clerical Office (John)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('01 703 3244'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                tooltip: 'Call Clerical Office',
                onPressed: () => _launchPhoneCall('017033244', context),
              ),
              onTap: () => _launchPhoneCall('017033244', context),
            ),
          ),
          const SizedBox(height: 8), // Spacer between cards
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                child: const Icon(Icons.medical_services, color: Colors.purple), // Icon for CMO
              ),
              title: const Text(
                'CMO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('01 703 1308'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                tooltip: 'Call CMO',
                onPressed: () => _launchPhoneCall('017031308', context),
              ),
              onTap: () => _launchPhoneCall('017031308', context),
            ),
          ),
          const SizedBox(height: 8), // Spacer between cards
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                child: const Icon(Icons.support_agent, color: Colors.teal), // Icon for controller
              ),
              title: const Text(
                '39s Controller',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('01 703 1141'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                tooltip: 'Call 39s Controller',
                onPressed: () => _launchPhoneCall('017031141', context),
              ),
              onTap: () => _launchPhoneCall('017031141', context),
            ),
          ),
          const SizedBox(height: 8), // Spacer between cards
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                child: const Icon(Icons.support_agent, color: Colors.teal), // Icon for controller
              ),
              title: const Text(
                '9/122 Controller',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('01 703 1132'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                tooltip: 'Call 9/122 Controller',
                onPressed: () => _launchPhoneCall('017031132', context),
              ),
              onTap: () => _launchPhoneCall('017031132', context),
            ),
          ),
          const SizedBox(height: 8), // Spacer between cards
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                child: const Icon(Icons.support_agent, color: Colors.teal), // Icon for controller
              ),
              title: const Text(
                'Cs Controller',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('01 703 1136'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                tooltip: 'Call Cs Controller',
                onPressed: () => _launchPhoneCall('017031136', context),
              ),
              onTap: () => _launchPhoneCall('017031136', context),
            ),
          ),
        ],
      ),
    );
  }
}
