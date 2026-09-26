import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_key.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_service.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

class DutyRatingsAdminScreen extends StatelessWidget {
  const DutyRatingsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty Ratings'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remove notes without changing scores. Delete a vote only if it is spam.',
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DutyRatingVote>>(
              stream: DutyRatingService.watchPublicNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load notes',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }

                final notes = snapshot.data ?? [];
                if (notes.isEmpty) {
                  return const Center(child: Text('No public notes'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final vote = notes[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(vote.note),
                      subtitle: Text(
                        '${vote.dutyCode} · ${DutyRatingKey.dayTypeLabel(vote.dayType)} · ${vote.date} · score ${vote.score}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'remove') {
                            await DutyRatingService.removeNote(vote.id);
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete this rating?'),
                                content: const Text(
                                  'This removes the score from the average. Use only for spam.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await DutyRatingService.deleteVote(vote);
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove note'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete rating'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
