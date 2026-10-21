import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spdrivercalendar/features/calendar/utils/board_share_capture.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

/// Shares a PNG of the whole board, the same way a duty card is shared.
class BoardShareButton extends StatefulWidget {
  const BoardShareButton({
    super.key,
    required this.board,
    this.color,
  });

  final UniversalBoard board;
  final Color? color;

  @override
  State<BoardShareButton> createState() => _BoardShareButtonState();
}

class _BoardShareButtonState extends State<BoardShareButton> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final bytes = await captureBoardPng(
        context: context,
        board: widget.board,
      );
      if (!mounted) return;
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: boardShareFileName(widget.board),
          ),
        ],
        subject: 'Board ${widget.board.shift}',
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? IconTheme.of(context).color;
    return IconButton(
      tooltip: 'Share board',
      onPressed: _sharing ? null : _share,
      icon: _sharing
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          : Icon(Icons.share_outlined, color: color),
    );
  }
}
