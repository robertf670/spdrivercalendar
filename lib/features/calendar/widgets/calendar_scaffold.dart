import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spdrivercalendar/features/calendar/controllers/calendar_controller.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_live_updates_banner.dart';
import 'package:spdrivercalendar/models/live_update.dart';
import 'package:spdrivercalendar/services/live_update_banner_dismiss_service.dart';
import 'package:spdrivercalendar/services/live_updates_service.dart';

/// Menu values for the calendar overflow actions.
abstract final class CalendarMenuAction {
  static const bills = 'bills';
  static const timingPoints = 'timing_points';
  static const toiletCodes = 'toilet_codes';
  static const statistics = 'statistics';
  static const addHolidays = 'add_holidays';
  static const contacts = 'contacts';
  static const notes = 'notes';
  static const liveUpdates = 'live_updates';
  static const payscale = 'payscale';
  static const settings = 'settings';

  /// Active diversion count for the menu label (includes banner-dismissed).
  static int activeLiveUpdateCount(List<LiveUpdate> items) {
    return items.where((item) => item.isUpdate && item.isActive).length;
  }

  static String liveUpdatesLabel(List<LiveUpdate> items) {
    final count = activeLiveUpdateCount(items);
    return count > 0 ? 'Live Updates ($count)' : 'Live Updates';
  }
}

/// Presentation scaffold for the main calendar screen.
///
/// Navigation and feature flows stay with the caller via callbacks.
class CalendarScaffold extends StatelessWidget {
  const CalendarScaffold({
    super.key,
    required this.scrollController,
    required this.calendar,
    required this.dayDetailBuilder,
    required this.onSearch,
    required this.onWeekView,
    required this.onMenuSelected,
    this.activeUpdatesStream,
  });

  final ScrollController scrollController;
  final Widget calendar;
  final Widget Function(DateTime selectedDay) dayDetailBuilder;
  final VoidCallback onSearch;
  final VoidCallback onWeekView;
  final ValueChanged<String> onMenuSelected;
  final Stream<List<LiveUpdate>>? activeUpdatesStream;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textScaleFactor = textScaler.scale(1.0);
    final bool useShortAppBarTitle =
        textScaleFactor > 1.12 || MediaQuery.sizeOf(context).width < 400;
    final double? appBarToolbarHeight =
        textScaleFactor > 1.2 ? kToolbarHeight + 10.0 : null;

    return StreamBuilder<List<LiveUpdate>>(
      stream:
          activeUpdatesStream ?? LiveUpdatesService.getActiveUpdatesStream(),
      builder: (context, bannerSnapshot) {
        final streamItems = bannerSnapshot.data ?? const <LiveUpdate>[];
        final liveUpdatesLabel =
            CalendarMenuAction.liveUpdatesLabel(streamItems);

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: appBarToolbarHeight,
            title: Text(
              useShortAppBarTitle ? 'Calendar' : 'Spare Driver Calendar',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search Shifts',
                onPressed: onSearch,
              ),
              IconButton(
                icon: const Icon(Icons.view_week),
                tooltip: 'Week View',
                onPressed: onWeekView,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: CalendarMenuAction.bills,
                    child: Text('Bills'),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.timingPoints,
                    child: Text('Timing Points'),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.toiletCodes,
                    child: Text('Toilet Codes'),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.statistics,
                    child: Text('Statistics'),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.addHolidays,
                    child: Text('Holidays'),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.contacts,
                    child: Text('Contacts'),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.notes,
                    child: Text('Notes'),
                  ),
                  PopupMenuItem(
                    value: CalendarMenuAction.liveUpdates,
                    child: Text(liveUpdatesLabel),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.payscale,
                    child: Text('Pay Scale'),
                  ),
                  const PopupMenuItem(
                    value: CalendarMenuAction.settings,
                    child: Text('Settings'),
                  ),
                ],
                onSelected: onMenuSelected,
              ),
            ],
          ),
          body: FutureBuilder<void>(
            future: LiveUpdateBannerDismissService.ensureLoaded(),
            builder: (context, _) {
              return ValueListenableBuilder<Set<String>>(
                valueListenable: LiveUpdateBannerDismissService.dismissedIds,
                builder: (context, _, __) {
                  final visibleUpdates =
                      LiveUpdateBannerDismissService.visibleForBanner(
                    streamItems,
                  );
                  final showBanner = visibleUpdates.isNotEmpty;

                  return Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: showBanner ? 90 : 0),
                        child: Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(3),
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: SafeArea(
                              top: false,
                              child: Column(
                                children: [
                                  calendar,
                                  const SizedBox(height: 16),
                                  Selector<CalendarController, DateTime?>(
                                    selector: (_, controller) =>
                                        controller.selectedDay,
                                    builder: (_, selectedDay, __) {
                                      if (selectedDay == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return dayDetailBuilder(selectedDay);
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.viewPaddingOf(context)
                                            .bottom +
                                        24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showBanner)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: CalendarLiveUpdatesBanner(
                            updates: visibleUpdates,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
