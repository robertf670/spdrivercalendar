import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Day-level notes editor. Persistence stays with the caller via [onSave].
class DayNotesDialog extends StatefulWidget {
  const DayNotesDialog({
    super.key,
    required this.date,
    required this.initialNotes,
    required this.onSave,
  });

  final DateTime date;
  final String initialNotes;
  final Future<void> Function(String? notes) onSave;

  @override
  State<DayNotesDialog> createState() => _DayNotesDialogState();
}

class _DayNotesDialogState extends State<DayNotesDialog> {
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (screenWidth < 350) {
      return {
        'widthFactor': 0.95,
        'heightFactor': 0.45,
        'inset': 12.0,
      };
    }
    return {
      'widthFactor': 0.9,
      'heightFactor': 0.4,
      'inset': 24.0,
    };
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final updatedNotes = _notesController.text.trim();
    await widget.onSave(updatedNotes.isEmpty ? null : updatedNotes);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: sizes['inset']!,
        vertical: 24,
      ),
      title: Row(
        children: [
          const Icon(Icons.notes_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Notes for ${DateFormat('EEE, MMM d').format(widget.date)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: SizedBox(
        width: screenWidth * sizes['widthFactor']!,
        height: screenHeight * sizes['heightFactor']!,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _notesController,
            maxLines: null,
            minLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Add notes for this day...',
              border: const OutlineInputBorder(),
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              filled: true,
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  _notesController.clear();
                },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
