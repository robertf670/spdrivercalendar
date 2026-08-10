import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/notes/widgets/duty_notes_editor.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

typedef SaveEventDutyNotes = Future<void> Function(
  String? notes,
  List<String>? imagePaths,
);

/// Duty-notes editor that delegates event persistence to its caller.
class EventDutyNotesDialog extends StatefulWidget {
  const EventDutyNotesDialog({
    super.key,
    required this.event,
    required this.scaffoldContext,
    required this.onSave,
  });

  final Event event;
  final BuildContext scaffoldContext;
  final SaveEventDutyNotes onSave;

  @override
  State<EventDutyNotesDialog> createState() => _EventDutyNotesDialogState();
}

class _EventDutyNotesDialogState extends State<EventDutyNotesDialog> {
  late final TextEditingController _notesController;
  final GlobalKey<DutyNotesEditorState> _editorKey =
      GlobalKey<DutyNotesEditorState>();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.event.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogBackground = theme.dialogTheme.backgroundColor ??
        theme.colorScheme.surfaceContainerHigh;
    final viewSize = MediaQuery.sizeOf(context);
    final screenWidth = viewSize.width;
    final screenHeight = viewSize.height;
    final horizontalPadding = screenWidth < 350 ? 12.0 : 16.0;
    final verticalPadding = screenWidth < 350 ? 10.0 : 12.0;
    final dialogWidth = math.min(screenWidth * 0.92, 560.0);
    final dialogHeight = math.min(
      screenHeight * 0.88,
      screenHeight * (screenWidth < 350 ? 0.65 : 0.58),
    );

    return Dialog(
      backgroundColor: dialogBackground,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 24.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.notes_rounded, color: AppTheme.primaryColor),
                  SizedBox(width: screenWidth < 350 ? 6 : 8),
                  Text('Notes', style: theme.textTheme.titleLarge),
                ],
              ),
              SizedBox(height: screenWidth < 350 ? 10 : 12),
              Expanded(
                child: DutyNotesEditor(
                  key: _editorKey,
                  event: widget.event,
                  textController: _notesController,
                ),
              ),
              SizedBox(height: screenWidth < 350 ? 8 : 10),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 6,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _notesController.clear();
                        _editorKey.currentState?.clearImages();
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Clear'),
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final text = _notesController.text.trim();
    List<String>? newPaths;
    try {
      newPaths = await _editorKey.currentState?.persistAttachments();
    } catch (error) {
      if (widget.scaffoldContext.mounted) {
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          SnackBar(content: Text('Could not save photos: $error')),
        );
      }
      return;
    }

    final sameText = text == (widget.event.notes ?? '');
    final sameImages = const ListEquality<String>().equals(
      newPaths ?? <String>[],
      widget.event.noteImagePaths ?? <String>[],
    );
    if (!sameText || !sameImages) {
      await widget.onSave(
        text.isEmpty ? null : text,
        newPaths,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
