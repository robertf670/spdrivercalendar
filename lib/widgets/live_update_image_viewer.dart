import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:spdrivercalendar/services/note_attachment_service.dart';

/// Opens a full-screen live-update image with pinch-zoom, rotate, and share.
Future<void> openLiveUpdateImageViewer(
  BuildContext context, {
  required String imageUrl,
  String shareFileName = 'live_update.jpg',
}) {
  final w = MediaQuery.sizeOf(context).width;
  final pad = w < 350 ? 8.0 : 12.0;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) {
      return LiveUpdateImageViewerDialog(
        imageUrl: imageUrl,
        shareFileName: shareFileName,
        insetPadding: pad,
      );
    },
  );
}

class LiveUpdateImageViewerDialog extends StatefulWidget {
  const LiveUpdateImageViewerDialog({
    super.key,
    required this.imageUrl,
    required this.shareFileName,
    required this.insetPadding,
  });

  final String imageUrl;
  final String shareFileName;
  final double insetPadding;

  @override
  State<LiveUpdateImageViewerDialog> createState() =>
      _LiveUpdateImageViewerDialogState();
}

class _LiveUpdateImageViewerDialogState
    extends State<LiveUpdateImageViewerDialog> {
  Uint8List? _bytes;
  Object? _error;
  bool _sharing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _error = 'Could not load image (${response.statusCode})';
          _loading = false;
        });
        return;
      }
      setState(() {
        _bytes = response.bodyBytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _rotate() async {
    final bytes = _bytes;
    if (bytes == null) return;
    final rotated =
        await compute(NoteAttachmentService.rotateClockwise90, bytes);
    if (!mounted) return;
    setState(() => _bytes = rotated);
  }

  Future<void> _sharePhoto() async {
    final bytes = _bytes;
    if (bytes == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/jpeg',
            name: widget.shareFileName,
          ),
        ],
        subject: 'Live update image',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not share image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = MediaQuery.sizeOf(context).width < 350 ? 24.0 : 28.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(widget.insetPadding),
      child: Material(
        color: Colors.black,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(4),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _error != null || _bytes == null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error?.toString() ?? 'Image unavailable',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          )
                        : InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(64),
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.memory(
                              _bytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
              ),
              if (_bytes != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.rotate_right,
                          color: Colors.white,
                          size: iconSize,
                        ),
                        tooltip: 'Rotate',
                        onPressed: _rotate,
                      ),
                      IconButton(
                        icon: _sharing
                            ? SizedBox(
                                width: iconSize,
                                height: iconSize,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.share,
                                color: Colors.white,
                                size: iconSize,
                              ),
                        tooltip: 'Share / save photo',
                        onPressed: _sharing ? null : _sharePhoto,
                      ),
                    ],
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: iconSize),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
