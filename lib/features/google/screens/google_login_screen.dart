import 'package:flutter/material.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class GoogleLoginScreen extends StatefulWidget {
  final VoidCallback onLoginComplete;
  
  const GoogleLoginScreen({
    super.key,
    required this.onLoginComplete,
  });
  
  @override
  GoogleLoginScreenState createState() => GoogleLoginScreenState();
}

class GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  
  Map<String, double> _loginResponsiveSizes(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final pad = w < 350 ? 16.0 : w < 400 ? 20.0 : 28.0;
    double iconBase = w < 350 ? 72.0 : w < 450 ? 96.0 : 120.0;
    if (textScale > 1.15) {
      iconBase = iconBase / (textScale * 0.8);
    }
    final iconSize = iconBase.clamp(56.0, 120.0);
    final gap = (w < 350 ? 16.0 : 20.0) * (textScale > 1.25 ? 0.85 : 1.0);
    return {'pad': pad, 'iconSize': iconSize, 'gap': gap};
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _loginResponsiveSizes(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connect to Google Calendar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.all(sizes['pad']!),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: sizes['iconSize']!,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: sizes['gap']!),
                      Text(
                        'Sync with Google Calendar',
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: sizes['gap']! * 0.75),
                      Text(
                        'Connect your account to sync your shifts between this app and Google Calendar.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: sizes['gap']!),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Google Calendar access requires test user approval. Please use the feedback section to request access with your email address.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: sizes['gap']!),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSignIn,
                          icon: const Icon(Icons.login),
                          label: Text(_isLoading ? 'Connecting...' : 'Connect with Google'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            surfaceTintColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: sizes['gap']! * 0.75),
                      TextButton(
                        onPressed: _isLoading ? null : _handleSkip,
                        child: const Text('Skip for now'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final account = await GoogleCalendarService.signInWithGoogle();
      
      if (account != null) {
        // Successfully signed in
        await StorageService.saveBool(AppConstants.hasCompletedGoogleLoginKey, true);
        widget.onLoginComplete();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign-in was cancelled or failed.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error connecting to Google: $e';
      });
    }
  }

  Future<void> _handleSkip() async {
    await StorageService.saveBool(AppConstants.hasCompletedGoogleLoginKey, true);
    widget.onLoginComplete();
  }
}
