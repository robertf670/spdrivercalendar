import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/oauth_helper.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';

class GoogleLoginPage extends StatefulWidget {
  final VoidCallback onLoginComplete;
  
  const GoogleLoginPage({Key? key, required this.onLoginComplete}) : super(key: key);

  @override
  _GoogleLoginPageState createState() => _GoogleLoginPageState();
}

class _GoogleLoginPageState extends State<GoogleLoginPage> {
  bool _isLoading = false;
  String _statusMessage = '';
  String _errorMessage = '';
  GoogleSignInAccount? _currentUser;
  bool _showTestingRestrictionInfo = false;

  // Update the GoogleSignIn initialization to include the calendar scope
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Checking login status...';
      });

      final user = await GoogleCalendarService.getCurrentUser();
      
      // If we have a user but can't access calendar, we need to re-authenticate
      if (user != null) {
        final hasAccess = await GoogleCalendarService.checkCalendarAccess();
        if (!hasAccess) {
          print('User found but calendar access failed, need to re-authenticate');
          // Force re-authentication
          await GoogleCalendarService.signOut();
          setState(() {
            _currentUser = null;
            _statusMessage = 'Session expired. Please sign in again.';
          });
          return;
        }
      }
      
      setState(() {
        _currentUser = user;
        if (user != null) {
          _statusMessage = 'Signed in as ${user.displayName}';
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
      final account = await GoogleCalendarService.signIn();
      
      if (account != null) {
        print('Successfully signed in: ${account.email}');
        setState(() {
          _currentUser = account;
          _statusMessage = 'Successfully signed in as ${account.displayName}';
        });
        
        // Save that login is completed
        await GoogleCalendarService.saveLoginStatus(true);
        return;
      }
      
      // If direct sign-in fails, show verification dialog
      final shouldContinue = await OAuthHelper.showVerificationBypassDialog(context);
      
      if (shouldContinue == true) {
        final retryAccount = await GoogleCalendarService.signIn();
        
        if (retryAccount != null) {
          print('Successfully signed in after verification dialog: ${retryAccount.email}');
          setState(() {
            _currentUser = retryAccount;
            _statusMessage = 'Successfully signed in as ${retryAccount.displayName}';
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
              if (_currentUser == null)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign in with Google',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              
              // Already logged in message
              if (_currentUser != null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Signed in as ${_currentUser!.displayName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.email,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Add test calendar button with clearer instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Calendar Integration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the button below to create a test event in your calendar. '
                            'The event will appear 1 hour from now.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Create Test Event'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                final success = await CalendarTestHelper.addTestEvent(context);
                                if (success) {
                                  setState(() {
                                    _statusMessage = 'Test event added to your calendar';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Make the continue button more prominent
                    ElevatedButton(
                      onPressed: widget.onLoginComplete,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text(
                        'Continue to App',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 16),
              
              // Skip option
              if (_currentUser == null)
                TextButton(
                  onPressed: _handleSkip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              
              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('Error')
                          ? Colors.red
                          : _statusMessage.contains('Successfully')
                              ? Colors.green
                              : Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Error message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Testing restriction info
              if (_showTestingRestrictionInfo)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Testing Mode Restriction',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This app is currently in testing mode with Google. Only approved test users can access it.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
