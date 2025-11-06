import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:spdrivercalendar/models/event.dart'; // Assuming Event model path
import 'package:spdrivercalendar/features/calendar/services/event_service.dart'; // Assuming EventService path
import 'package:spdrivercalendar/theme/app_theme.dart'; // For consistent styling
import 'package:spdrivercalendar/features/notes/screens/edit_note_screen.dart'; // Import the edit screen
import 'package:collection/collection.dart'; // Import for groupBy

class AllNotesScreen extends StatefulWidget {
  const AllNotesScreen({super.key});

  @override
  AllNotesScreenState createState() => AllNotesScreenState();
}

class AllNotesScreenState extends State<AllNotesScreen> {
  List<Event> _allNotes = []; // Holds all notes originally loaded
  Map<String, List<Event>> _groupedNotes = {}; // Map for grouped notes
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
      // Get all events with notes using the new method
      final eventsWithNotes = await EventService.getAllEventsWithNotes();
      final uniqueEventsWithNotes = <String, Event>{};
      for (var event in eventsWithNotes) {
         final eventId = event.id;
         if (eventId.isNotEmpty) { 
             uniqueEventsWithNotes[eventId] = event;
         }
      }
      final uniqueList = uniqueEventsWithNotes.values.toList();
      uniqueList.sort((a, b) => b.startDate.compareTo(a.startDate));

      if (mounted) {
        setState(() {
          _allNotes = uniqueList; // Store all loaded notes
          _filterAndGroupNotes(); // Group notes after loading
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
    List<Event> filtered = _allNotes;

    // Apply month filter if selected
    if (_selectedMonth != null) {
      filtered = filtered.where((event) {
        final eventDate = event.startDate;
        return eventDate.year == _selectedMonth!.year && 
               eventDate.month == _selectedMonth!.month;
      }).toList();
    }

    // Apply search filter
    if (query.isNotEmpty) {
      filtered = filtered.where((event) {
        final titleMatch = event.title.toLowerCase().contains(query);
        final noteMatch = event.notes?.toLowerCase().contains(query) ?? false;
        return titleMatch || noteMatch;
      }).toList();
    }

    // Group the filtered notes by date key
    setState(() {
      _groupedNotes = groupBy(filtered, (Event event) => _getGroupKey(event.startDate));
    });
  }

  // --- Delete Note Logic ---
  Future<void> _deleteNote(Event eventToDelete) async {
    final updatedEvent = eventToDelete.copyWith(notes: ''); 
    try {
      await EventService.updateEvent(eventToDelete, updatedEvent);
      if (mounted) {
        // Remove from the master list first
        _allNotes.removeWhere((event) => event.id == eventToDelete.id);
        // Then re-filter and re-group
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

  // --- Confirmation Dialog ---
  Future<void> _showDeleteConfirmationDialog(Event eventToDelete) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete the note for "${eventToDelete.title}" on ${DateFormat('dd/MM/yyyy').format(eventToDelete.startDate)}?'),
                const SizedBox(height: 8),
                Text('Note: ${eventToDelete.notes}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                _deleteNote(eventToDelete);     
              },
            ),
          ],
        );
      },
    );
  }

  // --- Navigate to Edit Screen ---
  Future<void> _navigateToEditNoteScreen(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditNoteScreen(event: event)),
    );

    // If the edit screen returned true (meaning saved), refresh the notes list
    if (result == true && mounted) {
      _loadNotes(); // Reload notes to see the changes
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
                  shrinkWrap: true, // Important for nested ListView
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
                  itemCount: notesInGroup.length,
                  itemBuilder: (context, noteIndex) {
                    final event = notesInGroup[noteIndex];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0), // Reduced vertical margin
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 16.0, right: 0, top: 10.0, bottom: 10.0),
                        // Note: Title is now the Duty/Event Title within the group
                        title: GestureDetector(
                           onTap: () => _navigateToDateInCalendar(event.startDate),
                           child: Text(
                             DateFormat('dd/MM/yyyy').format(event.startDate),
                             style: TextStyle(
                               fontSize: 12, // Smaller date text when grouped
                               // Use a theme-aware color with opacity for better dark mode visibility
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
                                event.title, // Duty/Event Title is prominent now
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.notes ?? '', 
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
                          onPressed: () => _showDeleteConfirmationDialog(event),
                        ),
                        onTap: () => _navigateToEditNoteScreen(event),
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
