import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/event.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Event) onEventAdded;

  const AddEventDialog({
    super.key,
    required this.selectedDate,
    required this.onEventAdded,
  });

  @override
  AddEventDialogState createState() => AddEventDialogState();
}

class AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(
      hour: TimeOfDay.now().hour + 1,
      minute: TimeOfDay.now().minute,
    );
  }

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones)
    if (screenWidth < 350) {
      return {
        'contentPadding': 12.0,        // Reduced from default ~16-20
        'spacing': 12.0,                // Reduced from 16
        'rowSpacing': 6.0,             // Reduced from 8
        'dropdownPadding': 4.0,        // Reduced from 8
        'titleSpacing': 10.0,           // Reduced spacing
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'contentPadding': 14.0,
        'spacing': 14.0,
        'rowSpacing': 7.0,
        'dropdownPadding': 5.0,
        'titleSpacing': 12.0,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'contentPadding': 16.0,
        'spacing': 15.0,
        'rowSpacing': 7.5,
        'dropdownPadding': 6.0,
        'titleSpacing': 14.0,
      };
    }
    // Regular phones and larger
    else {
      return {
        'contentPadding': 20.0,        // Default AlertDialog padding
        'spacing': 16.0,                // Original size
        'rowSpacing': 8.0,             // Original size
        'dropdownPadding': 8.0,        // Original size
        'titleSpacing': 16.0,          // Original size
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AlertDialog(
      title: const Text('Add Event'),
      contentPadding: EdgeInsets.all(sizes['contentPadding']!),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              SizedBox(height: sizes['spacing']!),
              const Text('Start', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: sizes['titleSpacing']! * 0.25),
              // Stack date and time vertically on very small screens
              screenWidth < 350
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          child: Text(DateFormat('dd-MM-yyyy').format(_startDate)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate;
                                }
                              });
                            }
                          },
                        ),
                        SizedBox(height: sizes['rowSpacing']!),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'H',
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: sizes['dropdownPadding']!,
                                    vertical: sizes['dropdownPadding']!,
                                  ),
                                ),
                                value: _startTime.hour,
                                items: List.generate(24, (index) => index).map((hour) {
                                  return DropdownMenuItem(
                                    value: hour,
                                    child: Text(hour.toString().padLeft(2, '0')),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _startTime = TimeOfDay(hour: value, minute: _startTime.minute);
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: sizes['rowSpacing']! * 0.5),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'M',
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: sizes['dropdownPadding']!,
                                    vertical: sizes['dropdownPadding']!,
                                  ),
                                ),
                                value: _startTime.minute,
                                items: List.generate(60, (index) => index).map((minute) {
                                  return DropdownMenuItem(
                                    value: minute,
                                    child: Text(minute.toString().padLeft(2, '0')),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _startTime = TimeOfDay(hour: _startTime.hour, minute: value);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            child: Text(DateFormat('dd-MM-yyyy').format(_startDate)),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _startDate = date;
                                  if (_endDate.isBefore(_startDate)) {
                                    _endDate = _startDate;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(width: sizes['rowSpacing']!),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'H',
                                    border: const OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: sizes['dropdownPadding']!,
                                      vertical: sizes['dropdownPadding']!,
                                    ),
                                  ),
                                  value: _startTime.hour,
                                  items: List.generate(24, (index) => index).map((hour) {
                                    return DropdownMenuItem(
                                      value: hour,
                                      child: Text(hour.toString().padLeft(2, '0')),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _startTime = TimeOfDay(hour: value, minute: _startTime.minute);
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: sizes['rowSpacing']! * 0.5),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'M',
                                    border: const OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: sizes['dropdownPadding']!,
                                      vertical: sizes['dropdownPadding']!,
                                    ),
                                  ),
                                  value: _startTime.minute,
                                  items: List.generate(60, (index) => index).map((minute) {
                                    return DropdownMenuItem(
                                      value: minute,
                                      child: Text(minute.toString().padLeft(2, '0')),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _startTime = TimeOfDay(hour: _startTime.hour, minute: value);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: sizes['spacing']!),
              const Text('End', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: sizes['titleSpacing']! * 0.25),
              // Stack date and time vertically on very small screens
              screenWidth < 350
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          child: Text(DateFormat('dd-MM-yyyy').format(_endDate)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                        ),
                        SizedBox(height: sizes['rowSpacing']!),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'H',
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: sizes['dropdownPadding']!,
                                    vertical: sizes['dropdownPadding']!,
                                  ),
                                ),
                                value: _endTime.hour,
                                items: List.generate(24, (index) => index).map((hour) {
                                  return DropdownMenuItem(
                                    value: hour,
                                    child: Text(hour.toString().padLeft(2, '0')),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _endTime = TimeOfDay(hour: value, minute: _endTime.minute);
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: sizes['rowSpacing']! * 0.5),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'M',
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: sizes['dropdownPadding']!,
                                    vertical: sizes['dropdownPadding']!,
                                  ),
                                ),
                                value: _endTime.minute,
                                items: List.generate(60, (index) => index).map((minute) {
                                  return DropdownMenuItem(
                                    value: minute,
                                    child: Text(minute.toString().padLeft(2, '0')),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _endTime = TimeOfDay(hour: _endTime.hour, minute: value);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            child: Text(DateFormat('dd-MM-yyyy').format(_endDate)),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _endDate = date;
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(width: sizes['rowSpacing']!),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'H',
                                    border: const OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: sizes['dropdownPadding']!,
                                      vertical: sizes['dropdownPadding']!,
                                    ),
                                  ),
                                  value: _endTime.hour,
                                  items: List.generate(24, (index) => index).map((hour) {
                                    return DropdownMenuItem(
                                      value: hour,
                                      child: Text(hour.toString().padLeft(2, '0')),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _endTime = TimeOfDay(hour: value, minute: _endTime.minute);
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: sizes['rowSpacing']! * 0.5),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'M',
                                    border: const OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: sizes['dropdownPadding']!,
                                      vertical: sizes['dropdownPadding']!,
                                    ),
                                  ),
                                  value: _endTime.minute,
                                  items: List.generate(60, (index) => index).map((minute) {
                                    return DropdownMenuItem(
                                      value: minute,
                                      child: Text(minute.toString().padLeft(2, '0')),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _endTime = TimeOfDay(hour: _endTime.hour, minute: value);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveEvent,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveEvent() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final eventStartDate = DateTime(
      _startDate.year, _startDate.month, _startDate.day
    );
    final eventEndDate = DateTime(
      _endDate.year, _endDate.month, _endDate.day
    );

    // Check if end date/time is before start date/time
    final startDateTime = DateTime(
      eventStartDate.year, 
      eventStartDate.month, 
      eventStartDate.day,
      _startTime.hour,
      _startTime.minute
    );
    
    final endDateTime = DateTime(
      eventEndDate.year, 
      eventEndDate.month, 
      eventEndDate.day,
      _endTime.hour,
      _endTime.minute
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before start time')),
      );
      return;
    }

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      startDate: eventStartDate,
      startTime: _startTime,
      endDate: eventEndDate,
      endTime: _endTime,
    );

    widget.onEventAdded(event);
    Navigator.of(context).pop();
  }
}
