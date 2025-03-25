import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  
  const WelcomeScreen({
    Key? key,
    required this.onGetStarted,
  }) : super(key: key);
  
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
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
                  return _buildWelcomePage(
                    _welcomePages[index]['title'],
                    _welcomePages[index]['description'],
                    _welcomePages[index]['icon'],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_welcomePages.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  
                  // Navigation buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _currentPage < _welcomePages.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : widget.onGetStarted,
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
  
  Widget _buildWelcomePage(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
