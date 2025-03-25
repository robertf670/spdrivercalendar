import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OAuthHelper {
  /// Shows a dialog explaining the Google verification issue and how to bypass it
  static Future<bool?> showVerificationBypassDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Google Test Mode Restriction'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'This app is currently in test mode with Google and can only be accessed by approved test users.',
                ),
                SizedBox(height: 16),
                Text(
                  'Options to resolve:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. If you created this app yourself, add your Google account as a test user in the Google Cloud Console'),
                Text('2. Use a different Google account that has been approved for testing'),
                Text('3. Continue without Google Calendar integration for now'),
                SizedBox(height: 16),
                Text(
                  'Note: While in development, Google restricts app access to only approved test users for security.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Learn More'),
              onPressed: () {
                openGoogleTestingHelp();
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Skip Google Login'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  /// Opens support documentation about Google testing restrictions
  static void openGoogleTestingHelp() async {
    const url = 'https://support.google.com/cloud/answer/10311615';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
