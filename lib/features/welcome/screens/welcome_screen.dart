import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
  });
  
  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<Map<String, dynamic>> _welcomePages = [
    {
      'title': 'Welcome to Spare Driver Calendar',
      'description': 'The perfect app to manage your shifts as a spare driver.',
      'icon': Icons.calendar_month,
    },
    {
      'title': 'Track Your Shifts',
      'description': 'Add, edit, and manage your work shifts with ease.',
      'icon': Icons.work,
    },
    {
      'title': 'Bus Tracking',
      'description': 'Add the buses you drive to keep track of them.',
      'icon': Icons.work,
    },
    {
      'title': 'Google Calendar Integration',
      'description': 'Sync your shifts with Google Calendar to access them anywhere.',
      'icon': Icons.sync,
    },
    {
      'title': 'Statistics and Insights',
      'description': 'Get insights about your work patterns and shifts, and your work time.',
      'icon': Icons.insert_chart,
    },
    {
      'title': 'Holiday Management',
      'description': 'Add and track your given holidays, and any personal holidays alongside your shifts.',
      'icon': Icons.event_busy,
    },
    {
      'title': 'Add Notes to Events',
      'description': 'Easily add and view notes for any shift or event directly from the event card.',
      'icon': Icons.note_add,
    },
    {
      'title': 'Contacts Page',
      'description': 'Quickly access important phone numbers and contact information.',
      'icon': Icons.contacts,
    },
    {
      'title': 'Provide Feedback',
      'description': 'Your feedback is valuable! Use the feedback option in the menu to share your thoughts or report issues.',
      'icon': Icons.feedback,
    },
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Map<String, double> _welcomeResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final pad = screenWidth < 350 ? 16.0 : screenWidth < 400 ? 20.0 : 24.0;
    final bottomPad = screenWidth < 350 ? 12.0 : 16.0;
    double iconBase =
        screenWidth < 350 ? 64.0 : screenWidth < 400 ? 80.0 : screenWidth < 600 ? 100.0 : 120.0;
    if (textScale > 1.15) {
      iconBase = iconBase / (textScale * 0.75);
    }
    final iconSize = iconBase.clamp(48.0, 120.0);
    final gapLarge = (screenWidth < 350 ? 20.0 : 28.0) * (textScale > 1.25 ? 0.9 : 1.0);
    final gapSmall = (screenWidth < 350 ? 12.0 : 16.0) * (textScale > 1.25 ? 0.9 : 1.0);
    return {
      'pad': pad,
      'bottomPad': bottomPad,
      'iconSize': iconSize,
      'gapLarge': gapLarge,
      'gapSmall': gapSmall,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _welcomeResponsiveSizes(context);
    final bottomPad = sizes['bottomPad']!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _welcomePages.length,
                itemBuilder: (context, index) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: sizes['pad']!,
                          vertical: sizes['pad']!,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: _buildWelcomePage(
                            _welcomePages[index]['title'],
                            _welcomePages[index]['description'],
                            _welcomePages[index]['icon'],
                            sizes,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(bottomPad, 8, bottomPad, bottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_welcomePages.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).width < 380 ? 10 : 14),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Back'),
                        ),
                      ElevatedButton(
                        onPressed: _currentPage < _welcomePages.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : widget.onGetStarted,
                        style: ElevatedButton.styleFrom(
                          surfaceTintColor: Colors.transparent,
                        ),
                        child: Text(
                          _currentPage < _welcomePages.length - 1
                              ? 'Next'
                              : 'Get Started',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(
    String title,
    String description,
    IconData icon,
    Map<String, double> sizes,
  ) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: MediaQuery.sizeOf(context).width < 350 ? 18 : 22,
          color: theme.colorScheme.onSurface,
        );
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
        ) ??
        TextStyle(
          fontSize: MediaQuery.sizeOf(context).width < 350 ? 14 : 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
        );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: sizes['iconSize']!,
          color: AppTheme.primaryColor,
        ),
        SizedBox(height: sizes['gapLarge']!),
        Text(
          title,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sizes['gapSmall']!),
        Text(
          description,
          style: bodyStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
