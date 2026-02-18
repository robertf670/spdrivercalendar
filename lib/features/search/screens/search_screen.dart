import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/event_search_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _busController = TextEditingController();
  final TextEditingController _dutyController = TextEditingController();
  
  List<Event> _searchResults = [];
  bool _isSearching = false;
  bool _showFilters = false; // Default hidden
  
  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedShiftType;
  bool _overtimeOnly = false;
  bool _hasNotes = false;
  String? _selectedSickDayType;
  bool _holidaysOnly = false;
  bool _sickDaysOnly = false;
  
  final List<String> _shiftTypes = [
    'SP',
    'PZ',
    'UNI',
    'Early',
    'Late',
    'Relief',
    'Night',
  ];
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
    _busController.addListener(_performSearch);
    _dutyController.addListener(_performSearch);
    // Run initial search to show all events when no filters are in place
    WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _busController.dispose();
    _dutyController.dispose();
    super.dispose();
  }
  
  Future<void> _performSearch() async {
    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await EventSearchService.searchEvents(
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        busNumber: _busController.text.trim().isEmpty ? null : _busController.text.trim(),
        dutyCode: _dutyController.text.trim().isEmpty ? null : _dutyController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        shiftType: _selectedShiftType,
        overtimeOnly: _overtimeOnly ? true : null,
        hasNotes: _hasNotes ? true : null,
        sickDayType: _selectedSickDayType,
        holidaysOnly: _holidaysOnly ? true : null,
        sickDaysOnly: _sickDaysOnly ? true : null,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
  
  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedShiftType = null;
      _overtimeOnly = false;
      _hasNotes = false;
      _selectedSickDayType = null;
      _holidaysOnly = false;
      _sickDaysOnly = false;
    });
    _performSearch();
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _performSearch();
    }
  }
  
  String _getEventSummary(Event event) {
    final List<String> parts = [];
    
    // Add duty codes
    if (event.hasEnhancedDuties && event.enhancedAssignedDuties!.isNotEmpty) {
      final dutyCodes = event.enhancedAssignedDuties!.map((d) => d.dutyCode).join(', ');
      parts.add('Duties: $dutyCodes');
    } else if (event.assignedDuties != null && event.assignedDuties!.isNotEmpty) {
      parts.add('Duties: ${event.assignedDuties!.join(', ')}');
    }
    
    // Add bus numbers
    final List<String> buses = [];
    if (event.firstHalfBus != null) buses.add(event.firstHalfBus!);
    if (event.secondHalfBus != null) buses.add(event.secondHalfBus!);
    if (event.busAssignments != null) {
      buses.addAll(event.busAssignments!.values.where((b) => b.isNotEmpty));
    }
    if (event.hasEnhancedDuties) {
      for (final duty in event.enhancedAssignedDuties!) {
        if (duty.assignedBus != null && duty.assignedBus!.isNotEmpty) {
          buses.add(duty.assignedBus!);
        }
      }
    }
    if (buses.isNotEmpty) {
      parts.add('Bus: ${buses.join(', ')}');
    }
    
    return parts.join(' • ');
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Shifts'),
      ),
      body: Column(
        children: [
          // Search bar with improved styling
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: isSmallScreen 
                        ? 'Search shifts...' 
                        : 'Search by title, duty code, notes...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    isDense: isSmallScreen,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                // Responsive layout: stack on small screens, row on larger
                if (isSmallScreen) ...[
                  TextField(
                    controller: _busController,
                    decoration: InputDecoration(
                      labelText: 'Bus Number',
                      hintText: 'e.g., 1234',
                      prefixIcon: Icon(
                        Icons.directions_bus,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      suffixIcon: _busController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _busController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dutyController,
                    decoration: InputDecoration(
                      labelText: 'Duty Code',
                      hintText: 'e.g., PZ1',
                      prefixIcon: Icon(
                        Icons.route,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      suffixIcon: _dutyController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _dutyController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busController,
                          decoration: InputDecoration(
                            labelText: 'Bus Number',
                            hintText: 'e.g., 1234',
                            prefixIcon: Icon(
                              Icons.directions_bus,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            suffixIcon: _busController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _busController.clear();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dutyController,
                          decoration: InputDecoration(
                            labelText: 'Duty Code',
                            hintText: 'e.g., PZ1',
                            prefixIcon: Icon(
                              Icons.route,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            suffixIcon: _dutyController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _dutyController.clear();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Filters toggle button/label
          InkWell(
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: isSmallScreen ? 18 : 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : null,
                            ),
                      ),
                    ],
                  ),
                  Icon(
                    _showFilters ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          
          // Filters panel - expandable, default hidden
          if (_showFilters)
            Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: isSmallScreen ? 18 : 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filters',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 13 : null,
                                ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 4 : 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear All',
                          style: TextStyle(fontSize: isSmallScreen ? 12 : null),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                    
                // Responsive filter layout
                if (isSmallScreen) ...[
                  // Date range button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                            : 'Date Range',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Shift type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedShiftType,
                    decoration: InputDecoration(
                      labelText: 'Shift Type',
                      prefixIcon: const Icon(Icons.access_time, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Types', style: TextStyle(fontSize: 12)),
                      ),
                      ..._shiftTypes.map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type, style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedShiftType = value;
                      });
                      _performSearch();
                    },
                  ),
                  const SizedBox(height: 8),
                  // Checkboxes in a row
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Overtime', style: TextStyle(fontSize: 11)),
                        selected: _overtimeOnly,
                        onSelected: (value) {
                          setState(() {
                            _overtimeOnly = value;
                          });
                          _performSearch();
                        },
                      ),
                      FilterChip(
                        label: const Text('Has Notes', style: TextStyle(fontSize: 11)),
                        selected: _hasNotes,
                        onSelected: (value) {
                          setState(() {
                            _hasNotes = value;
                          });
                          _performSearch();
                        },
                      ),
                      FilterChip(
                        label: const Text('Holidays', style: TextStyle(fontSize: 11)),
                        selected: _holidaysOnly,
                        onSelected: (value) {
                          setState(() {
                            _holidaysOnly = value;
                          });
                          _performSearch();
                        },
                      ),
                      FilterChip(
                        label: const Text('Sick Days', style: TextStyle(fontSize: 11)),
                        selected: _sickDaysOnly,
                        onSelected: (value) {
                          setState(() {
                            _sickDaysOnly = value;
                          });
                          _performSearch();
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  // Desktop/tablet layout - filters in rows
                  Row(
                    children: [
                      // Date range
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                                : 'Date Range',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Shift type
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedShiftType,
                          decoration: const InputDecoration(
                            labelText: 'Shift Type',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Types'),
                            ),
                            ..._shiftTypes.map((type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedShiftType = value;
                            });
                            _performSearch();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Checkboxes row
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Overtime Only'),
                        selected: _overtimeOnly,
                        onSelected: (value) {
                          setState(() {
                            _overtimeOnly = value;
                          });
                          _performSearch();
                        },
                      ),
                      FilterChip(
                        label: const Text('Has Notes'),
                        selected: _hasNotes,
                        onSelected: (value) {
                          setState(() {
                            _hasNotes = value;
                          });
                          _performSearch();
                        },
                      ),
                      FilterChip(
                        label: const Text('Holidays Only'),
                        selected: _holidaysOnly,
                        onSelected: (value) {
                          setState(() {
                            _holidaysOnly = value;
                          });
                          _performSearch();
                        },
                      ),
                      FilterChip(
                        label: const Text('Sick Days Only'),
                        selected: _sickDaysOnly,
                        onSelected: (value) {
                          setState(() {
                            _sickDaysOnly = value;
                          });
                          _performSearch();
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(padding),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final event = _searchResults[index];
                          final isSickDay = event.sickDayType != null;
                          final isHoliday = event.isHoliday;
                          final isOvertime = event.title.contains('(OT)') || event.overtimeDuration != null;
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              side: BorderSide(
                                color: isSickDay
                                    ? Colors.orange.withValues(alpha: 0.3)
                                    : isHoliday
                                        ? AppTheme.holidayColor.withValues(alpha: 0.3)
                                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            color: isSickDay
                                ? Colors.orange.withValues(alpha: 0.05)
                                : isHoliday
                                    ? AppTheme.holidayColor.withValues(alpha: 0.05)
                                    : null,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              onTap: () {
                                Navigator.of(context).pop(event.startDate);
                              },
                              child: Padding(
                                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon badge
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSickDay
                                            ? Colors.orange.withValues(alpha: 0.2)
                                            : isHoliday
                                                ? AppTheme.holidayColor.withValues(alpha: 0.2)
                                                : isOvertime
                                                    ? Colors.amber.withValues(alpha: 0.2)
                                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isSickDay
                                            ? Icons.medical_services
                                            : isHoliday
                                                ? Icons.event_busy
                                                : isOvertime
                                                    ? Icons.access_time
                                                    : Icons.work,
                                        color: isSickDay
                                            ? Colors.orange
                                            : isHoliday
                                                ? AppTheme.holidayColor
                                                : isOvertime
                                                    ? Colors.amber
                                                    : Theme.of(context).colorScheme.primary,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  event.title,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontSize: isSmallScreen ? 14 : null,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSickDay || isHoliday || isOvertime) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isSickDay
                                                        ? Colors.orange.withValues(alpha: 0.2)
                                                        : isHoliday
                                                            ? AppTheme.holidayColor.withValues(alpha: 0.2)
                                                            : Colors.amber.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isSickDay
                                                        ? 'SICK'
                                                        : isHoliday
                                                            ? 'HOLIDAY'
                                                            : 'OT',
                                                    style: TextStyle(
                                                      fontSize: isSmallScreen ? 8 : 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSickDay
                                                          ? Colors.orange.shade800
                                                          : isHoliday
                                                              ? AppTheme.holidayColor
                                                              : Colors.amber.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          SizedBox(height: isSmallScreen ? 4 : 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: isSmallScreen ? 12 : 14,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  isSmallScreen
                                                      ? DateFormat('MMM d, yyyy').format(event.startDate)
                                                      : DateFormat('EEEE, MMMM d, yyyy').format(event.startDate),
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        fontSize: isSmallScreen ? 12 : null,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: isSmallScreen ? 12 : 14,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontSize: isSmallScreen ? 11 : null,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          if (_getEventSummary(event).isNotEmpty) ...[
                                            SizedBox(height: isSmallScreen ? 4 : 6),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: isSmallScreen ? 12 : 14,
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _getEventSummary(event),
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                          fontSize: isSmallScreen ? 10 : null,
                                                        ),
                                                    maxLines: isSmallScreen ? 1 : 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (event.notes != null && event.notes!.isNotEmpty) ...[
                                            SizedBox(height: isSmallScreen ? 4 : 6),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.note,
                                                  size: isSmallScreen ? 12 : 14,
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    event.notes!,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          fontStyle: FontStyle.italic,
                                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                          fontSize: isSmallScreen ? 10 : null,
                                                        ),
                                                    maxLines: isSmallScreen ? 1 : 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      size: isSmallScreen ? 20 : 24,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Results count
          if (_searchResults.isNotEmpty && !_isSearching)
            Container(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 6 : 8,
                horizontal: padding,
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isSmallScreen ? 11 : null,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

