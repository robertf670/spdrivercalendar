import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_admin_query.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_service.dart';
import 'package:spdrivercalendar/features/ratings/duty_rating_vote.dart';

class DutyRatingsAdminScreen extends StatefulWidget {
  const DutyRatingsAdminScreen({super.key});

  @override
  State<DutyRatingsAdminScreen> createState() => _DutyRatingsAdminScreenState();
}

class _DutyRatingsAdminScreenState extends State<DutyRatingsAdminScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _removeNote(DutyRatingVote vote) async {
    await DutyRatingService.removeNote(vote.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note removed')),
    );
  }

  Future<void> _deleteVote(DutyRatingVote vote) async {
    await DutyRatingService.deleteVote(vote);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duty Ratings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search duty, score, or note',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<DutyRatingVote>>(
                  stream: DutyRatingService.watchAllVotes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Could not load ratings'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rows = DutyRatingAdminQuery.apply(
                      votes: snapshot.data!,
                      search: _search.text,
                    );
                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          snapshot.data!.isEmpty
                              ? 'No ratings yet'
                              : 'No ratings match this search',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final vote = rows[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          isThreeLine: true,
                          title: Text(vote.dutyCode),
                          subtitle: Text(DutyRatingAdminQuery.subtitle(vote)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'note') {
                                _removeNote(vote);
                              } else if (value == 'delete') {
                                _deleteVote(vote);
                              }
                            },
                            itemBuilder: (context) => [
                              if (vote.hasPublicNote)
                                const PopupMenuItem(
                                  value: 'note',
                                  child: Text('Remove note'),
                                ),
                              const PopupMenuItem(
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
        ),
      ),
    );
  }
}
