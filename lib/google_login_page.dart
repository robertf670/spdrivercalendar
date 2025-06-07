import 'package:flutter/material.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/oauth_helper.dart';

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
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      
      // If we have a user email and they're signed in, test the connection
      if (userEmail != null && isSignedIn) {
        final hasAccess = await GoogleCalendarService.testConnection();
        if (!hasAccess) {
          print('[GoogleLogin] User found but calendar access failed, need to re-authenticate');
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
        if (userEmail != null && isSignedIn) {
          _statusMessage = 'Signed in as $userEmail';
        } else {
          _statusMessage = '';
        }
      });
    } catch (e) {
      print('[GoogleLogin] Error checking current user: $e');
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
      // Try signing in with interactive flow
      final accountEmail = await GoogleCalendarService.signInWithGoogle(interactive: true);
      
      if (accountEmail != null) {
        print('[GoogleLogin] Successfully signed in: $accountEmail');
        setState(() {
          _currentUserEmail = accountEmail;
          _statusMessage = 'Successfully signed in as $accountEmail';
        });
        
        // Test the connection to make sure everything works
        final hasAccess = await GoogleCalendarService.testConnection();
        if (hasAccess) {
          setState(() {
            _statusMessage = 'Successfully connected to Google Calendar';
          });
        } else {
          setState(() {
            _statusMessage = 'Signed in but calendar access limited. Check permissions.';
          });
        }
        
        return;
      }
      
      // If sign-in fails, show verification dialog
      print('[GoogleLogin] Initial sign-in failed, showing verification dialog');
      final shouldContinue = await OAuthHelper.showVerificationBypassDialog(context);
      
      if (shouldContinue == true) {
        final retryAccountEmail = await GoogleCalendarService.signInWithGoogle(interactive: true);
        
        if (retryAccountEmail != null) {
          print('[GoogleLogin] Successfully signed in after verification dialog: $retryAccountEmail');
          setState(() {
            _currentUserEmail = retryAccountEmail;
            _statusMessage = 'Successfully signed in as $retryAccountEmail';
          });
        } else {
          print('[GoogleLogin] Sign-in canceled or failed after verification dialog');
          setState(() {
            _statusMessage = 'Sign in canceled or failed';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Sign in canceled by user';
        });
      }
    } catch (error) {
      print('[GoogleLogin] Error during Google sign-in: $error');
      
      // Check if the error is about testing mode
      if (error.toString().contains('only be accessed by developer-approved testers') ||
          error.toString().contains('not completed') ||
          error.toString().contains('restricted') ||
          error.toString().contains('403')) {
        
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

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing out...';
    });

    try {
      await GoogleCalendarService.signOut();
      setState(() {
        _currentUserEmail = null;
        _statusMessage = '';
        _errorMessage = '';
      });
      print('[GoogleLogin] Successfully signed out');
    } catch (e) {
      print('[GoogleLogin] Error signing out: $e');
      setState(() {
        _errorMessage = 'Failed to sign out: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSkip() async {
    print('[GoogleLogin] User skipped Google sign-in');
    widget.onLoginComplete();
  }

  Future<void> _handleContinue() async {
    print('[GoogleLogin] User completed Google setup');
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
            tooltip: 'Skip and continue',
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Status message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Testing restriction info
              if (_showTestingRestrictionInfo)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'App in Testing Mode',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This Google Calendar integration is currently in testing mode. Contact the developer to be added as a test user, or try a different Google account.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 40),
              
              // Current user display
              if (_currentUserEmail != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connected to Google Calendar',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUserEmail!,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 40),
              
              // Action buttons
              if (_currentUserEmail == null) ...[
                // Sign in button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSignIn,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                  label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Skip button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleSkip,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip for now'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else ...[
                // Continue button (when signed in)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleContinue,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sign out button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleSignOut,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                  label: Text(_isLoading ? 'Signing out...' : 'Sign out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Privacy notice
              Text(
                'Your Google account information is only used for calendar integration and is not stored on external servers.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
