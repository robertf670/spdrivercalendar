import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:spdrivercalendar/models/event.dart'; // Assuming Event model path
import 'package:spdrivercalendar/features/calendar/services/event_service.dart'; // Assuming EventService path
import 'package:spdrivercalendar/theme/app_theme.dart'; // For consistent styling
import 'package:spdrivercalendar/features/notes/screens/edit_note_screen.dart'; // Import the edit screen
import 'package:collection/collection.dart'; // Import for groupBy

class AllNotesScreen extends StatefulWidget {
  const AllNotesScreen({Key? key}) : super(key: key);

  @override
  _AllNotesScreenState createState() => _AllNotesScreenState();
}

class _AllNotesScreenState extends State<AllNotesScreen> {
  List<Event> _allNotes = []; // Holds all notes originally loaded
  Map<String, List<Event>> _groupedNotes = {}; // Map for grouped notes
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // Store search query state

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
      final eventsMap = await EventService.getEvents(); 
      final allEvents = eventsMap.values.expand((list) => list).toList();
      final eventsWithNotes = allEvents.where((event) => event.notes != null && event.notes!.trim().isNotEmpty).toList();
      final uniqueEventsWithNotes = <String, Event>{};
      for (var event in eventsWithNotes) {
         final eventId = event.id;
         if (eventId != null) { 
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
      print("Error loading notes: $e");
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
    List<Event> filtered;

    if (query.isEmpty) {
      filtered = _allNotes;
    } else {
      filtered = _allNotes.where((event) {
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
      print("Error deleting note: $e");
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
      ),
      body: Column( // Use Column to place Search bar above the list
        children: [
          // --- Search Bar --- 
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                 // Add clear button
                 suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear(); // Clears text, listener calls _filterAndGroupNotes
                        },
                      )
                    : null,
              ),
            ),
          ),
          // --- Notes List --- 
          Expanded( // Make the list take remaining space
            child: _buildGroupedNotesList(), // Use the new grouped list builder
          ),
        ],
      ),
    );
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
        child: ListView( 
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
      );
    }

    // Get the sorted date group keys
    final dateGroups = _groupedNotes.keys.toList();
    // Note: The initial list was sorted descending, so groups should appear in correct order.
    // If explicit sorting of group keys is needed later, do it here.

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
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
                               color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
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
                                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8)),
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis, 
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.8)),
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
    );
  }
} 