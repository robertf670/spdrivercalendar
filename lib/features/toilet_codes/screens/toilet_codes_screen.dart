import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/toilet_codes_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class ToiletCodesScreen extends StatelessWidget {
  const ToiletCodesScreen({super.key});

  Map<String, double> _getSizes(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return {
      'padding': w < 350 ? 8.0 : w < 450 ? 10.0 : 12.0,
      'rowPad': w < 350 ? 4.0 : w < 450 ? 5.0 : 6.0,
      'fontSize': w < 350 ? 12.0 : w < 450 ? 13.0 : 14.0,
      'smallFontSize': w < 350 ? 10.0 : w < 450 ? 11.0 : 12.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getSizes(context);
    final padding = sizes['padding']!;
    final w = MediaQuery.of(context).size.width;
    final useGrid = w >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toilet Codes'),
        elevation: 0,
      ),
      body: StreamBuilder<List<ToiletCodeEntry>>(
        stream: ToiletCodesService.getEntriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load toilet codes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: sizes['fontSize'],
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wc,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No toilet codes yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: sizes['fontSize'],
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Codes are added via Admin Dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: sizes['smallFontSize']!,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (useGrid) {
            return Padding(
              padding: EdgeInsets.all(padding),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _ToiletCodeCell(
                    entry: entries[index],
                    sizes: sizes,
                    altBg: index % 2 == 1,
                  );
                },
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableHeader(sizes: sizes),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        return _ToiletCodeRow(
                          entry: entries[index],
                          sizes: sizes,
                          altBg: index % 2 == 1,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final Map<String, double> sizes;

  const _TableHeader({required this.sizes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fs = sizes['smallFontSize']!;
    final pad = sizes['rowPad']!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: pad + 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Location',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: fs,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Code',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: fs,
                color: Colors.white,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToiletCodeRow extends StatelessWidget {
  final ToiletCodeEntry entry;
  final Map<String, double> sizes;
  final bool altBg;

  const _ToiletCodeRow({
    required this.entry,
    required this.sizes,
    required this.altBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowPad = sizes['rowPad']!;
    final fontSize = sizes['fontSize']!;
    final smallSize = sizes['smallFontSize']!;
    final isDark = theme.brightness == Brightness.dark;

    final codesText = entry.codes.entries
        .map((e) => e.key == 'Code' ? e.value : '${e.key}: ${e.value}')
        .join('\n');

    final rowBg = altBg
        ? (isDark
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : AppTheme.primaryColor.withValues(alpha: 0.06))
        : Colors.transparent;

    final codeBg = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return Container(
      color: rowBg,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: rowPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              entry.locationName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: codeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      codesText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    if (entry.instruction != null &&
                        entry.instruction!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.instruction!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: smallSize,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToiletCodeCell extends StatelessWidget {
  final ToiletCodeEntry entry;
  final Map<String, double> sizes;
  final bool altBg;

  const _ToiletCodeCell({
    required this.entry,
    required this.sizes,
    required this.altBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = sizes['padding']!;
    final fontSize = sizes['fontSize']!;
    final smallSize = sizes['smallFontSize']!;
    final isDark = theme.brightness == Brightness.dark;

    final codesText = entry.codes.entries
        .map((e) => e.key == 'Code' ? e.value : '${e.key}: ${e.value}')
        .join('\n');

    final cellBg = altBg
        ? (isDark
            ? AppTheme.primaryColor.withValues(alpha: 0.12)
            : AppTheme.primaryColor.withValues(alpha: 0.05))
        : theme.colorScheme.surface;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            entry.locationName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              color: AppTheme.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.6 : 0.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              codesText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (entry.instruction != null &&
              entry.instruction!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              entry.instruction!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: smallSize,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
