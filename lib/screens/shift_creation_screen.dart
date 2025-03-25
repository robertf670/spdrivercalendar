import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/work_shift.dart';
import 'package:spdrivercalendar/services/shift_service.dart';
import 'package:uuid/uuid.dart';

class ShiftCreationScreen extends StatefulWidget {
  @override
  _ShiftCreationScreenState createState() => _ShiftCreationScreenState();
}

class _ShiftCreationScreenState extends State<ShiftCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 8));
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _addToGoogleCalendar = true; // Default to true for adding to Google Calendar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Shift'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Shift Title',
                  hintText: 'Enter the shift title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // Start time picker
              ListTile(
                title: Text('Start Time'),
                subtitle: Text(_startTime.toString()),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startTime,
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startTime),
                    );
                    
                    if (time != null) {
                      setState(() {
                        _startTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        
                        // Make sure end time is after start time
                        if (_endTime.isBefore(_startTime)) {
                          _endTime = _startTime.add(Duration(hours: 8));
                        }
                      });
                    }
                  }
                },
              ),
              
              // End time picker
              ListTile(
                title: Text('End Time'),
                subtitle: Text(_endTime.toString()),
                trailing: Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endTime,
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_endTime),
                    );
                    
                    if (time != null) {
                      setState(() {
                        _endTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                ),
              ),
              
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
                maxLines: 3,
              ),

              SwitchListTile(
                title: Text('Add to Google Calendar'),
                value: _addToGoogleCalendar,
                onChanged: (bool value) {
                  setState(() {
                    _addToGoogleCalendar = value;
                  });
                },
              ),
              
              SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: _saveShift,
                child: Text('Save Shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveShift() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      try {
        // Create a new shift object
        final shift = WorkShift(
          id: const Uuid().v4(),
          title: _titleController.text,
          startTime: _startTime,
          endTime: _endTime,
          location: _locationController.text,
          notes: _notesController.text,
        );
        
        // Save the shift to your app's storage
        await ShiftService.saveShift(shift);
        
        // If the user wants to add to Google Calendar, do so
        if (_addToGoogleCalendar) {
          final success = await shift.addToGoogleCalendar(context);
          if (!success) {
            print('Failed to add shift to Google Calendar');
          }
        }
        
        // Close the loading indicator
        Navigator.of(context).pop();
        
        // Show success message and return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shift saved successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        // Close the loading indicator
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving shift: $e')),
        );
      }
    }
  }
}
