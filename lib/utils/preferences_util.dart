import 'package:shared_preferences/shared_preferences.dart';

/// Marks the welcome page as seen in preferences
Future<void> markWelcomePageAsSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('hasSeenWelcome', true);
}

/// Retrieves whether the user has seen the welcome page
Future<bool> hasSeenWelcomePage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenWelcome') ?? false;
}
