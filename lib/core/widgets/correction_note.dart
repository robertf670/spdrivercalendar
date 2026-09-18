import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spdrivercalendar/core/utils/developer_correction.dart';

/// Plain-text correction prompt. Tapping opens WhatsApp to Rob.
class CorrectionNote extends StatelessWidget {
  const CorrectionNote({
    super.key,
    this.pageLabel = 'this page',
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final String pageLabel;
  final EdgeInsetsGeometry padding;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = developerCorrectionUri(pageLabel: pageLabel);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && messenger != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: InkWell(
        onTap: () => _open(context),
        child: Text.rich(
          TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.35,
            ),
            children: [
              const TextSpan(
                text: 'If you notice anything here to be incorrect, ',
              ),
              TextSpan(
                text: 'send me a message',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ),
    );
  }
}
