import 'package:flutter/material.dart';
import 'package:spdrivercalendar/screens/shift_creation_screen.dart';
import 'package:spdrivercalendar/screens/shift_list_screen.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spare Driver Calendar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShiftCreationScreen()),
                );
              },
              child: const Text('Create New Shift'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShiftListScreen()),
                );
              },
              child: const Text('View All Shifts'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await CalendarTestHelper.addTestEvent(context);
              },
              child: const Text('Add Test Event to Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}
