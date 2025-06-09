import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart'; // Assuming AppTheme has colors
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if validation fails
    }

    final feedback = _feedbackController.text;
    final theme = Theme.of(context); // Capture theme
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture ScaffoldMessenger

    // --- Replace placeholder with url_launcher logic ---
    const String recipientEmail = 'rob@ixrqq.pro'; // <-- *** REPLACE WITH YOUR EMAIL ***
    const String subject = 'Spare Driver Calendar App Feedback';
    final String body = feedback;

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        // Optionally show a confirmation that the email client was opened
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Opening email client to send feedback...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _feedbackController.clear(); // Clear the form
        }
      } else {
        // Handle case where mailto links cannot be launched (no email app?)
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Could not open email client. Please ensure an email app is configured.'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error opening email client: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper function to encode URL query parameters
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        elevation: 1,
      ),
      // Use SafeArea and SingleChildScrollView for better layout handling
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Added Icon for visual appeal
                const Icon(
                  Icons.feedback_outlined,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'We value your input!', // Slightly different wording
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor, // Use theme primary color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Share suggestions, report bugs, or tell us what you think. Your feedback helps improve the app.', // More detailed description
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), // Slightly muted color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _feedbackController,
                  maxLines: 8,
                  minLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Enter your feedback here...',
                    // labelText: 'Your Feedback', // Floating label might look cleaner
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      // Make border subtle when not focused
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                       borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    alignLabelWithHint: true,
                    filled: true,
                    // Use a slightly transparent fill color
                    fillColor: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your feedback before submitting.';
                    }
                    if (value.trim().length < 10) {
                      return 'Please provide a bit more detail (min 10 characters).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12), // Add spacing before the info text
                Text(
                  'This feedback will be sent directly to the app creator.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7), // Muted color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24), // Keep spacing before the button
                // Update Button: No loading state needed
                FilledButton.icon(
                  onPressed: _submitFeedback, // Directly call the submit function
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text('Send Feedback via Email'), // Updated label
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // Use primary color from AppTheme if available
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary, // Ensure contrast
                    textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                  ),
                ),
                 const SizedBox(height: 16), // Add some space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
