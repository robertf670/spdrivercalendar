import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/notes/widgets/duty_notes_editor.dart';
import 'package:spdrivercalendar/models/event.dart';

class EditNoteScreen extends StatefulWidget {
  final Event event;

  const EditNoteScreen({super.key, required this.event});

  @override
  EditNoteScreenState createState() => EditNoteScreenState();
}

class EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _noteController;
  final GlobalKey<DutyNotesEditorState> _editorKey = GlobalKey<DutyNotesEditorState>();
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
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final text = _noteController.text.trim();
    List<String>? paths;
    try {
      paths = await _editorKey.currentState?.persistAttachments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photos: $e')),
        );
      }
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final oldSnapshot = widget.event.copyWith();
    final sameText = text == (oldSnapshot.notes ?? '');
    final sameImg = const ListEquality<String>().equals(
      paths ?? <String>[],
      oldSnapshot.noteImagePaths ?? <String>[],
    );

    try {
      if (!sameText || !sameImg) {
        widget.event.notes = text.isEmpty ? null : text;
        widget.event.noteImagePaths = paths;
        await EventService.updateEvent(oldSnapshot, widget.event);
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
    final h = MediaQuery.sizeOf(context).height;
    final editorHeight = h < 600 ? h * 0.5 : h * 0.55;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Note',
                  onPressed: _saveNote,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(
              height: editorHeight,
              child: DutyNotesEditor(
                key: _editorKey,
                event: widget.event,
                textController: _noteController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
