import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:spdrivercalendar/models/event.dart'; // Assuming Event model path
import 'package:spdrivercalendar/features/calendar/services/event_service.dart'; // Assuming EventService path
import 'package:spdrivercalendar/services/day_note_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart'; // For consistent styling
import 'package:spdrivercalendar/features/notes/screens/edit_note_screen.dart'; // Import the edit screen
import 'package:collection/collection.dart'; // Import for groupBy

/// Unified note item for display - can be from an event or a day note.
class _NoteListItem {
  final DateTime date;
  final String title;
  final String note;
  final bool isDayNote;
  final Event? event;

  _NoteListItem({
    required this.date,
    required this.title,
    required this.note,
    this.isDayNote = false,
    this.event,
  });
}

class AllNotesScreen extends StatefulWidget {
  const AllNotesScreen({super.key});

  @override
  AllNotesScreenState createState() => AllNotesScreenState();
}

class AllNotesScreenState extends State<AllNotesScreen> {
  List<_NoteListItem> _allNotes = []; // Holds all notes (event + day notes)
  Map<String, List<_NoteListItem>> _groupedNotes = {}; // Map for grouped notes
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = ''; // Store search query state
  DateTime? _selectedMonth; // Add selected month state
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(() {
      // Update query state and trigger filter
      setState(() {
        _searchQuery = _searchController.text;
        _filterAndGroupNotes(); // Call combined filter/group method
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose controller
    _scrollController.dispose();
    super.dispose();
  }

  // --- Date Formatting and Grouping Key Logic ---
  String _getGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today';
    } else if (noteDate == yesterday) {
      return 'Yesterday';
    } else {
      // Consistent format for older dates
      return DateFormat('EEEE, dd MMMM yyyy').format(noteDate);
    }
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      // Load event notes and day notes in parallel
      final results = await Future.wait([
        EventService.getAllEventsWithNotes(),
        DayNoteService.getAllDayNotes(),
      ]);
      final eventsWithNotes = results[0] as List<Event>;
      final dayNotes = results[1] as List<({DateTime date, String note})>;

      final items = <_NoteListItem>[];

      // Add event notes
      final uniqueEventsWithNotes = <String, Event>{};
      for (var event in eventsWithNotes) {
        if (event.id.isNotEmpty && event.notes != null && event.notes!.trim().isNotEmpty) {
          uniqueEventsWithNotes[event.id] = event;
        }
      }
      for (var event in uniqueEventsWithNotes.values) {
        items.add(_NoteListItem(
          date: event.startDate,
          title: event.title,
          note: event.notes!,
          isDayNote: false,
          event: event,
        ));
      }

      // Add day notes (exclude dates that already have event notes with same content to avoid dupes - actually show both, they're different)
      for (var entry in dayNotes) {
        items.add(_NoteListItem(
          date: entry.date,
          title: 'Day note',
          note: entry.note,
          isDayNote: true,
        ));
      }

      items.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allNotes = items;
          _filterAndGroupNotes();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: ${e.toString()}'))
        );
      }
    }
  }

  // --- Combined Filter and Group Logic ---
  void _filterAndGroupNotes() {
    final query = _searchQuery.toLowerCase();
    List<_NoteListItem> filtered = _allNotes;

    // Apply month filter if selected
    if (_selectedMonth != null) {
      filtered = filtered.where((item) {
        return item.date.year == _selectedMonth!.year &&
               item.date.month == _selectedMonth!.month;
      }).toList();
    }

    // Apply search filter (title and note content)
    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query);
        final noteMatch = item.note.toLowerCase().contains(query);
        return titleMatch || noteMatch;
      }).toList();
    }

    // Group the filtered notes by date key
    setState(() {
      _groupedNotes = groupBy(filtered, (item) => _getGroupKey(item.date));
    });
  }

  // --- Delete Event Note Logic ---
  Future<void> _deleteEventNote(Event eventToDelete) async {
    final updatedEvent = eventToDelete.copyWith(notes: '');
    try {
      await EventService.updateEvent(eventToDelete, updatedEvent);
      if (mounted) {
        _allNotes.removeWhere((item) => !item.isDayNote && item.event?.id == eventToDelete.id);
        _filterAndGroupNotes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: ${e.toString()}')),
        );
      }
    }
  }

  // --- Delete Day Note Logic ---
  Future<void> _deleteDayNote(DateTime date) async {
    try {
      await DayNoteService.saveDayNote(date, null);
      if (mounted) {
        _allNotes.removeWhere((item) => item.isDayNote && _isSameDay(item.date, date));
        _filterAndGroupNotes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: ${e.toString()}')),
        );
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // --- Confirmation Dialog ---
  Future<void> _showDeleteConfirmationDialog(_NoteListItem item) async {
    final label = item.isDayNote ? 'Day note' : item.title;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete the note for "$label" on ${DateFormat('dd/MM/yyyy').format(item.date)}?'),
                const SizedBox(height: 8),
                Text('Note: ${item.note}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (item.isDayNote) {
                  _deleteDayNote(item.date);
                } else if (item.event != null) {
                  _deleteEventNote(item.event!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Navigate to Edit Screen (event notes) ---
  Future<void> _navigateToEditNoteScreen(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditNoteScreen(event: event)),
    );
    if (result == true && mounted) {
      _loadNotes();
    }
  }

  // --- Edit Day Note Dialog ---
  Future<void> _showDayNoteEditDialog(DateTime date, String currentNote) async {
    final notesController = TextEditingController(text: currentNote);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notes_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit note for ${DateFormat('EEE, MMM d').format(date)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: screenWidth * 0.9,
          height: screenHeight * 0.4,
          child: TextField(
            controller: notesController,
            maxLines: null,
            minLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Add notes for this day...',
              border: const OutlineInputBorder(),
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              filled: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => notesController.clear(),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedNote = notesController.text.trim();
              await DayNoteService.saveDayNote(date, updatedNote.isEmpty ? null : updatedNote);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      _loadNotes();
    }
  }

  // --- Navigate to Date in Calendar ---
  void _navigateToDateInCalendar(DateTime date) {
    // Pop back to the CalendarScreen (assuming it's the root or first route)
    // Pass the selected date back as a result
    Navigator.of(context).popUntil((route) => route.isFirst);
    // We will need to handle this result in CalendarScreen later
    // For now, just pop back. A more robust solution might use
    // a shared state management or pass arguments differently.
    Navigator.of(context).maybePop(date); // Attempt to pop with date
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notes'),
        elevation: 0,
        actions: [
          // Month picker button
          TextButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text(_selectedMonth == null 
              ? 'All Months' 
              : DateFormat('MMMM yyyy').format(_selectedMonth!)),
            onPressed: _showMonthPicker,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with month filter chip
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Search bar (expanded to take remaining space)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    ),
                  ),
                ),
                // Month filter chip (if month is selected)
                if (_selectedMonth != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: FilterChip(
                      label: Text(DateFormat('MMM yyyy').format(_selectedMonth!)),
                      onSelected: (_) {
                        setState(() {
                          _selectedMonth = null;
                          _filterAndGroupNotes();
                        });
                      },
                      selected: true,
                      showCheckmark: false,
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedMonth = null;
                          _filterAndGroupNotes();
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildGroupedNotesList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Month',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, null);
                          },
                          child: const Text('ALL'),
                        ),
                      ],
                    ),
                  ),
                  // Year selector
                  Container(
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          iconSize: 20,
                          onPressed: () {
                            setModalState(() {
                              _selectedYear = _selectedYear - 1;
                            });
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            '$_selectedYear',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          iconSize: 20,
                          onPressed: () {
                            setModalState(() {
                              _selectedYear = _selectedYear + 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Month grid
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final date = DateTime(_selectedYear, month);
                        final isSelected = _selectedMonth != null &&
                            _selectedMonth!.year == _selectedYear &&
                            _selectedMonth!.month == month;
                        final isCurrentMonth = date.year == DateTime.now().year &&
                            date.month == DateTime.now().month;
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context, date);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : isCurrentMonth
                                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
                                        : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrentMonth && !isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('MMM').format(date),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : isCurrentMonth
                                            ? Theme.of(context).colorScheme.primary
                                            : null,
                                    fontSize: 12,
                                    fontWeight: isSelected || isCurrentMonth ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Bottom padding for safe area
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).then((picked) {
      if (mounted) {
        setState(() {
          _selectedMonth = picked as DateTime?;
          _filterAndGroupNotes();
        });
      }
    });
  }

  // --- New Grouped List Builder ---
  Widget _buildGroupedNotesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedNotes.isEmpty) {
      final bool isSearching = _searchQuery.isNotEmpty;
      return RefreshIndicator(
        onRefresh: _loadNotes, 
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(3),
          child: ListView(
            controller: _scrollController,
            children: [
               const SizedBox(height: 150), 
               Center(
                child: Text(
                  isSearching ? 'No notes match your search.' : 'No notes found.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get the sorted date group keys
    final dateGroups = _groupedNotes.keys.toList();
    // Note: The initial list was sorted descending, so groups should appear in correct order.
    // If explicit sorting of group keys is needed later, do it here.

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(3),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8.0), // Padding for the whole list
          itemCount: dateGroups.length, // Number of date groups
          itemBuilder: (context, groupIndex) {
          final dateGroupKey = dateGroups[groupIndex];
          final notesInGroup = _groupedNotes[dateGroupKey]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // Space below each group
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Date Group Header ---
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    dateGroupKey, // e.g., "Today", "Yesterday", "Sunday, 27 October 2024"
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      // Use theme's primary color for better dark mode adaptation
                      color: Theme.of(context).colorScheme.primary, 
                    ),
                  ),
                ),
                // --- Notes within the Group ---
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notesInGroup.length,
                  itemBuilder: (context, noteIndex) {
                    final item = notesInGroup[noteIndex];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 16.0, right: 0, top: 10.0, bottom: 10.0),
                        title: GestureDetector(
                          onTap: () => _navigateToDateInCalendar(item.date),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(item.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.note,
                                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8)),
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.8)),
                          tooltip: 'Delete Note',
                          onPressed: () => _showDeleteConfirmationDialog(item),
                        ),
                        onTap: () {
                          if (item.isDayNote) {
                            _showDayNoteEditDialog(item.date, item.note);
                          } else if (item.event != null) {
                            _navigateToEditNoteScreen(item.event!);
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
} 
