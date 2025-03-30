import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class GoogleAccountCard extends StatelessWidget {
  final bool isLoading;
  final bool isGoogleSignedIn;
  final String googleAccountEmail;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const GoogleAccountCard({
    Key? key,
    required this.isLoading,
    required this.isGoogleSignedIn,
    required this.googleAccountEmail,
    required this.onSignIn,
    required this.onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Google Calendar'), // Generic title while loading
              SizedBox(height: 8),
              LinearProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGoogleSignedIn ? AppTheme.successColor : Colors.grey,
          child: Icon(
            isGoogleSignedIn ? Icons.check : Icons.login,
            color: Colors.white,
          ),
        ),
        title: Text(isGoogleSignedIn ? 'Google Calendar Connected' : 'Connect Google Calendar'),
        subtitle: Text(isGoogleSignedIn ? googleAccountEmail : 'Sync your shifts with Google Calendar'),
        trailing: isGoogleSignedIn
            ? IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'Sign out of Google', // Add tooltip
                onPressed: onSignOut,
              )
            : const Icon(Icons.chevron_right),
        onTap: isGoogleSignedIn ? null : onSignIn,
      ),
    );
  }
} 