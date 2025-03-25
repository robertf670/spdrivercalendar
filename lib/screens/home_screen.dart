import 'package:flutter/material.dart';
import 'package:spdrivercalendar/screens/shift_creation_screen.dart';
import 'package:spdrivercalendar/screens/shift_list_screen.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spare Driver Calendar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShiftCreationScreen()),
                );
              },
              child: Text('Create New Shift'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShiftListScreen()),
                );
              },
              child: Text('View All Shifts'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await CalendarTestHelper.addTestEvent(context);
              },
              child: Text('Add Test Event to Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}
