import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;
  
  const WelcomePage({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if we're showing from settings
    final isFromSettings = ModalRoute.of(context)?.settings.arguments as bool? ?? false;
    
    return Scaffold(
      appBar: isFromSettings ? AppBar(
        title: const Text('Welcome'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null, // Only show app bar if opened from settings
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // App title
              const Text(
                'Spare Driver Shift Calendar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              
              // Features section
              const Text(
                'Key Features:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Feature bullets
              _buildFeatureItem(
                icon: Icons.calendar_today,
                text: 'Track Your Shifts: View and manage your 5-week roster pattern',
              ),
              _buildFeatureItem(
                icon: Icons.sync,
                text: 'Automatically Update: Calendar shows Early, Late, and Rest days',
              ),
              _buildFeatureItem(
                icon: Icons.work,
                text: 'Add Work Shifts: Easily add your assigned shifts for any day',
              ),
              _buildFeatureItem(
                icon: Icons.bar_chart,
                text: 'View Statistics: Track your shift history and patterns',
              ),
              
              // Add information about duty data from Phibsboro Depot
              const SizedBox(height: 10),
              _buildInfoBox(
                text: 'This app contains all duty information from Phibsboro Depot to automatically load shifts into your calendar when chosen.',
              ),
              
              const Spacer(),
              
              // Get started section - only show if not from settings
              if (!isFromSettings) ...[
                const Text(
                  'Get Started:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose to add Google Calendar sync or not, you can do this later if you wish. Then choose your rest day pattern.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
              ],
              
              // Action buttons
              Center(
                child: ElevatedButton(
                  onPressed: isFromSettings 
                      ? () => Navigator.of(context).pop() // If from settings, just pop
                      : onGetStarted, // Otherwise use the normal flow
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: Text(
                    isFromSettings ? 'Close' : 'Get Started',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  // New method for the info box about Phibsboro Depot data
  Widget _buildInfoBox({required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 22, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Function to determine if we should show the welcome page
Future<bool> shouldShowWelcomePage() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('hasSeenWelcome') ?? false);
}

// Function to mark the welcome page as seen
Future<void> markWelcomePageAsSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('hasSeenWelcome', true);
}
