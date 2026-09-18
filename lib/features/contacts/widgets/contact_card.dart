import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.entry,
    required this.color,
    this.onCall,
    this.onEmail,
    this.onOpenLink,
  });

  final ContactEntry entry;
  final Color color;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onOpenLink;

  VoidCallback? get _primaryAction {
    if (entry.hasPhone) return onCall;
    if (entry.hasEmail) return onEmail;
    if (entry.hasUrl) return onOpenLink;
    return null;
  }

  IconData get _primaryActionIcon {
    if (entry.hasPhone) return Icons.phone;
    if (entry.hasEmail) return Icons.email;
    return Icons.open_in_new;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 600;
    final subtitle = entry.displaySubtitle;

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        onTap: _primaryAction,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ContactIcons.data(entry.iconKey),
                  color: color,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : null,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: isSmallScreen ? 12 : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _ActionTrail(
                entry: entry,
                isSmallScreen: isSmallScreen,
                primaryIcon: _primaryActionIcon,
                onCall: onCall,
                onEmail: onEmail,
                onOpenLink: onOpenLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTrail extends StatelessWidget {
  const _ActionTrail({
    required this.entry,
    required this.isSmallScreen,
    required this.primaryIcon,
    this.onCall,
    this.onEmail,
    this.onOpenLink,
  });

  final ContactEntry entry;
  final bool isSmallScreen;
  final IconData primaryIcon;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onOpenLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final iconSize = isSmallScreen ? 20.0 : 22.0;

    if (entry.actionCount <= 1) {
      return Icon(primaryIcon, size: iconSize, color: iconColor);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.hasPhone)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Call',
            icon: Icon(Icons.phone, size: iconSize, color: iconColor),
            onPressed: onCall,
          ),
        if (entry.hasEmail)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Email',
            icon: Icon(Icons.email, size: iconSize, color: iconColor),
            onPressed: onEmail,
          ),
        if (entry.hasUrl)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Open link',
            icon: Icon(Icons.open_in_new, size: iconSize, color: iconColor),
            onPressed: onOpenLink,
          ),
      ],
    );
  }
}
