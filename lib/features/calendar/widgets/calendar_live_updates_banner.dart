import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/live_update.dart';
import 'package:spdrivercalendar/screens/live_updates_details_screen.dart';
import 'package:spdrivercalendar/widgets/live_updates_banner.dart';

/// Calendar-specific live updates banner with its navigation kept at the
/// feature boundary.
class CalendarLiveUpdatesBanner extends StatelessWidget {
  const CalendarLiveUpdatesBanner({
    super.key,
    required this.updates,
  });

  final List<LiveUpdate> updates;

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return const SizedBox.shrink();
    }

    return LiveUpdatesBannerDisplay(
      updates: updates,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const LiveUpdatesDetailsScreen(),
          ),
        );
      },
    );
  }
}
