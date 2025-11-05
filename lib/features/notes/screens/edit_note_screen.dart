import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';

class EditNoteScreen extends StatefulWidget {
  final Event event;

  const EditNoteScreen({super.key, required this.event});

  @override
  EditNoteScreenState createState() => EditNoteScreenState();
}

class EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.event.notes ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_isSaving) return; // Prevent multiple saves
    setState(() { _isSaving = true; });

    final updatedNote = _noteController.text.trim();
    final originalEvent = widget.event;
    final updatedEvent = originalEvent.copyWith(notes: updatedNote);

    try {
      // Only call update if the note has actually changed
      if (originalEvent.notes != updatedNote) {
          await EventService.updateEvent(originalEvent, updatedEvent);
      }
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Note saved'), duration: Duration(seconds: 2)),
         );
         Navigator.of(context).pop(true); 
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: ${e.toString()}')),
        );
      }
    } finally {
       if (mounted) {
          setState(() { 
            _isSaving = false; 
          });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          // Save button - Corrected Ternary Structure
          _isSaving
            ? const Padding(
                padding: EdgeInsets.all(16.0), // Use EdgeInsets.all for consistency
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Note',
                onPressed: _saveNote,
              ), // Ensure comma is outside IconButton
        ], // Ensure actions list closes correctly
      ), // Ensure AppBar closes correctly
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Date and Title for context
            Text(
              'Date: ${DateFormat('dd/MM/yyyy').format(widget.event.startDate)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Duty: ${widget.event.title}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Note input field
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Enter your note here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true, // Better alignment for multi-line
              ),
              maxLines: null, // Allows multiple lines
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ), // Ensure Column closes correctly
      ), // Ensure SingleChildScrollView closes correctly
    ); // Ensure Scaffold closes correctly
  }
} 
