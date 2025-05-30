import 'package:flutter/material.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/oauth_helper.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class GoogleLoginPage extends StatefulWidget {
  final VoidCallback onLoginComplete;
  
  const GoogleLoginPage({Key? key, required this.onLoginComplete}) : super(key: key);

  @override
  _GoogleLoginPageState createState() => _GoogleLoginPageState();
}

class _GoogleLoginPageState extends State<GoogleLoginPage> {
  bool _isLoading = false;
  String? _currentUserEmail;
  String _statusMessage = '';
  String _errorMessage = '';
  bool _showTestingRestrictionInfo = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking login status...';
    });

    try {
      final userEmail = await GoogleCalendarService.getCurrentUserEmail();
      
      // If we have a user but can't access calendar, we need to re-authenticate
      if (userEmail != null) {
        // First, get an authenticated client
        final httpClient = await GoogleCalendarService.getAuthenticatedClient();
        final hasAccess = await GoogleCalendarService.checkCalendarAccess(httpClient); // Pass the client
        if (!hasAccess) {
          print('User found but calendar access failed, need to re-authenticate');
          // Force re-authentication
          await GoogleCalendarService.signOut();
          setState(() {
            _currentUserEmail = null;
            _statusMessage = 'Session expired. Please sign in again.';
          });
          return;
        }
      }
      
      setState(() {
        _currentUserEmail = userEmail;
        if (userEmail != null) {
          _statusMessage = 'Signed in as $userEmail';
        } else {
          _statusMessage = '';
        }
      });
    } catch (e) {
      print('Error checking current user: $e');
      setState(() {
        _errorMessage = 'Failed to check login status: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in...';
      _errorMessage = '';
      _showTestingRestrictionInfo = false;
    });

    try {
      // First, try signing in without showing the dialog
      // This will help if it's just a session expiration issue
      final accountEmail = await GoogleCalendarService.signInWithGoogle();
      
      if (accountEmail != null) {
        print('Successfully signed in: $accountEmail');
        setState(() {
          _currentUserEmail = accountEmail;
          _statusMessage = 'Successfully signed in as $accountEmail';
        });
        
        // Save that login is completed
        await GoogleCalendarService.saveLoginStatus(true);
        return;
      }
      
      // If direct sign-in fails, show verification dialog
      final shouldContinue = await OAuthHelper.showVerificationBypassDialog(context);
      
      if (shouldContinue == true) {
        final retryAccountEmail = await GoogleCalendarService.signInWithGoogle();
        
        if (retryAccountEmail != null) {
          print('Successfully signed in after verification dialog: $retryAccountEmail');
          setState(() {
            _currentUserEmail = retryAccountEmail;
            _statusMessage = 'Successfully signed in as $retryAccountEmail';
          });
          
          // Save that login is completed
          await GoogleCalendarService.saveLoginStatus(true);
        } else {
          print('Sign-in canceled or failed after verification dialog');
          setState(() {
            _statusMessage = 'Sign in canceled';
          });
        }
      }
    } catch (error) {
      print('Error during Google sign-in: $error');
      
      // Check if the error is about testing mode
      if (error.toString().contains('only be accessed by developer-approved testers') ||
          error.toString().contains('not completed')) {
        
        setState(() {
          _showTestingRestrictionInfo = true;
          _errorMessage = 'This app is in testing mode and requires approval. Try another Google account or continue without Google Calendar.';
        });
        
        // Show the dialog with appropriate guidance
        final shouldRetry = await OAuthHelper.showVerificationBypassDialog(context);
        if (shouldRetry == true) {
          // If user wants to try again, restart the sign-in process
          _handleSignIn();
          return;
        }
      } else {
        setState(() {
          _errorMessage = 'Error signing in: ${error.toString()}';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSkip() async {
    print('User skipped Google sign-in');
    // Mark login as completed even though user skipped
    await GoogleCalendarService.saveLoginStatus(true);
    widget.onLoginComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Google Calendar'),
        // Add a close button to allow manual exit without testing
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => widget.onLoginComplete(),
            tooltip: 'Skip testing and continue',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title section
              const Text(
                'Connect with Google Calendar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Explanatory text
              const Text(
                'Connecting your Google Calendar allows you to sync your work shifts automatically. The app can add/edit/delete your shifts automatically in Google Calendar - This can make it easy to share your calendar with other people should you wish.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Google icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/google_logo.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.calendar_month, size: 40, color: Colors.blue);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Sign in button
              if (_currentUserEmail == null)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSignIn,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                  label: Text(_isLoading ? 'Signing in...' : 'Connect Google Calendar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    foregroundColor: Colors.blue,
                  ),
                ),
              
              // Sign out button (when signed in)
              if (_currentUserEmail != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Successfully Connected!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Signed in as $_currentUserEmail',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () async {
                    await GoogleCalendarService.signOut();
                    setState(() {
                      _currentUserEmail = null;
                      _statusMessage = '';
                    });
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Skip button
              TextButton(
                onPressed: _isLoading ? null : _handleSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  foregroundColor: Colors.grey[600],
                ),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Status message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              // Testing restriction info
              if (_showTestingRestrictionInfo)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'App in Testing Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This app is currently in testing mode and can only be used by approved testers. You can:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Try a different Google account\n'
                        '• Continue using the app without Google Calendar sync\n'
                        '• Contact the developer for testing access',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 40),
              
              // Continue button (when signed in)
              if (_currentUserEmail != null)
                ElevatedButton(
                  onPressed: widget.onLoginComplete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Continue to App'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
