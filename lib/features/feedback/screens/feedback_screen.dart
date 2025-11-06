import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart'; // Assuming AppTheme has colors
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  FeedbackScreenState createState() => FeedbackScreenState();
}

class FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _feedbackController.dispose();
    _scrollController.dispose();
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

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones)
    if (screenWidth < 350) {
      return {
        'padding': 12.0,              // Reduced from 24
        'iconSize': 48.0,              // Reduced from 64
        'iconSpacing': 12.0,           // Reduced from 16
        'titleSpacing': 10.0,          // Reduced from 12
        'textFieldSpacing': 20.0,      // Reduced from 32
        'infoSpacing': 10.0,           // Reduced from 12
        'buttonSpacing': 16.0,         // Reduced from 24
        'bottomSpacing': 12.0,         // Reduced from 16
        'buttonPadding': 12.0,         // Reduced from 16
        'buttonIconSize': 18.0,        // Reduced from 20
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'padding': 16.0,
        'iconSize': 52.0,
        'iconSpacing': 14.0,
        'titleSpacing': 11.0,
        'textFieldSpacing': 24.0,
        'infoSpacing': 11.0,
        'buttonSpacing': 20.0,
        'bottomSpacing': 14.0,
        'buttonPadding': 14.0,
        'buttonIconSize': 19.0,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'padding': 18.0,
        'iconSize': 56.0,
        'iconSpacing': 15.0,
        'titleSpacing': 12.0,
        'textFieldSpacing': 28.0,
        'infoSpacing': 12.0,
        'buttonSpacing': 22.0,
        'bottomSpacing': 15.0,
        'buttonPadding': 15.0,
        'buttonIconSize': 20.0,
      };
    }
    // Regular phones
    else if (screenWidth < 600) {
      return {
        'padding': 20.0,
        'iconSize': 60.0,
        'iconSpacing': 16.0,
        'titleSpacing': 12.0,
        'textFieldSpacing': 30.0,
        'infoSpacing': 12.0,
        'buttonSpacing': 24.0,
        'bottomSpacing': 16.0,
        'buttonPadding': 16.0,
        'buttonIconSize': 20.0,
      };
    }
    // Tablets
    else if (screenWidth < 900) {
      return {
        'padding': 22.0,
        'iconSize': 62.0,
        'iconSpacing': 16.0,
        'titleSpacing': 12.0,
        'textFieldSpacing': 32.0,
        'infoSpacing': 12.0,
        'buttonSpacing': 24.0,
        'bottomSpacing': 16.0,
        'buttonPadding': 16.0,
        'buttonIconSize': 20.0,
      };
    }
    // Large tablets/desktop
    else {
      return {
        'padding': 24.0,              // Original size
        'iconSize': 64.0,             // Original size
        'iconSpacing': 16.0,          // Original size
        'titleSpacing': 12.0,         // Original size
        'textFieldSpacing': 32.0,     // Original size
        'infoSpacing': 12.0,          // Original size
        'buttonSpacing': 24.0,        // Original size
        'bottomSpacing': 16.0,        // Original size
        'buttonPadding': 16.0,        // Original size
        'buttonIconSize': 20.0,       // Original size
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final sizes = _getResponsiveSizes(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        elevation: 1,
      ),
      // Use SafeArea and SingleChildScrollView for better layout handling
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(3),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(sizes['padding']!),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Added Icon for visual appeal
                Icon(
                  Icons.feedback_outlined,
                  size: sizes['iconSize']!,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: sizes['iconSpacing']!),
                Text(
                  'We value your input!', // Slightly different wording
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor, // Use theme primary color
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: sizes['titleSpacing']!),
                Text(
                  'Share suggestions, report bugs, or tell us what you think. Your feedback helps improve the app.', // More detailed description
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), // Slightly muted color
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: sizes['textFieldSpacing']!),
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
                      borderSide: const BorderSide(
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
                SizedBox(height: sizes['infoSpacing']!), // Add spacing before the info text
                Text(
                  'This feedback will be sent directly to the app creator.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7), // Muted color
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: sizes['buttonSpacing']!), // Keep spacing before the button
                // Update Button: No loading state needed
                FilledButton.icon(
                  onPressed: _submitFeedback, // Directly call the submit function
                  icon: Icon(Icons.send_rounded, size: sizes['buttonIconSize']!),
                  label: const Text('Send Feedback via Email'), // Updated label
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: sizes['buttonPadding']!),
                    // Use primary color from AppTheme if available
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary, // Ensure contrast
                    textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                  ),
                ),
                 SizedBox(height: sizes['bottomSpacing']!), // Add some space at the bottom
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
} 
