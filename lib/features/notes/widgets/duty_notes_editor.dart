import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/note_attachment_service.dart';

/// Text field + up to [NoteAttachmentService.maxImagesPerEvent] gallery images for a duty note.
class DutyNotesEditor extends StatefulWidget {
  const DutyNotesEditor({
    super.key,
    required this.event,
    required this.textController,
  });

  final Event event;
  final TextEditingController textController;

  @override
  DutyNotesEditorState createState() => DutyNotesEditorState();
}

class DutyNotesEditorState extends State<DutyNotesEditor> {
  List<Uint8List> _images = [];
  bool _loading = true;

  List<Uint8List> get imageBytes => List.unmodifiable(_images);

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final paths = widget.event.noteImagePaths;
    if (paths == null || paths.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final out = <Uint8List>[];
    for (final f in paths) {
      final b = await NoteAttachmentService.readImage(widget.event.id, f);
      if (b != null) out.add(b);
    }
    if (mounted) {
      setState(() {
        _images = out;
        _loading = false;
      });
    }
  }

  /// Clears staged images (and local files on next [persistAttachments]).
  void clearImages() {
    setState(() => _images = []);
  }

  /// Writes JPEGs to storage and returns filenames for [Event.noteImagePaths], or `null` if none.
  Future<List<String>?> persistAttachments() async {
    if (_images.isEmpty) {
      await NoteAttachmentService.deleteAllForEvent(widget.event.id);
      return null;
    }
    return NoteAttachmentService.replaceAllImages(widget.event.id, _images);
  }

  Future<void> _addFromGallery() async {
    if (_images.length >= NoteAttachmentService.maxImagesPerEvent) return;
    final bytes = await NoteAttachmentService.pickFromGallery();
    if (bytes == null || !mounted) return;
    setState(() => _images = [..._images, bytes]);
  }

  void _removeAt(int index) {
    setState(() {
      _images = List<Uint8List>.from(_images)..removeAt(index);
    });
  }

  double _thumbSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 350) return 52;
    if (w < 450) return 58;
    return 64;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final thumb = _thumbSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextField(
            controller: widget.textController,
            maxLines: null,
            minLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Add notes here...',
              border: const OutlineInputBorder(),
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              filled: true,
            ),
          ),
        ),
        SizedBox(height: MediaQuery.sizeOf(context).width < 350 ? 8 : 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _images.length; i++)
              _AttachmentThumb(
                bytes: _images[i],
                size: thumb,
                onRemove: () => _removeAt(i),
                onView: () => _openDutyNotePhotoViewer(context, _images[i]),
              ),
            if (_images.length < NoteAttachmentService.maxImagesPerEvent)
              _AddPhotoTile(size: thumb, onTap: _addFromGallery),
          ],
        ),
      ],
    );
  }
}

/// Full screen + pinch zoom for a duty note photo.
void _openDutyNotePhotoViewer(BuildContext context, Uint8List bytes) {
  final w = MediaQuery.sizeOf(context).width;
  final pad = w < 350 ? 8.0 : 12.0;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(pad),
        child: Material(
          color: Colors.black,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(4),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(64),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({
    required this.bytes,
    required this.size,
    required this.onRemove,
    required this.onView,
  });

  final Uint8List bytes;
  final double size;
  final VoidCallback onRemove;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onView,
            borderRadius: BorderRadius.circular(8),
            child: Semantics(
              label: 'View full size',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.black87,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: size * 0.45,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
