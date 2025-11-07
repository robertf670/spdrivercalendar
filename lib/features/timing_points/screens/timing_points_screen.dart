import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/models/timing_point.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class TimingPointsScreen extends StatefulWidget {
  const TimingPointsScreen({super.key});

  @override
  TimingPointsScreenState createState() => TimingPointsScreenState();
}

class TimingPointsScreenState extends State<TimingPointsScreen> {
  List<TimingPointRoute> _routes = [];
  bool _isLoading = true;
  String _selectedRoute = '';
  String _selectedDestination = '';
  List<String> _availableRoutes = [];
  List<String> _availableDestinations = [];
  List<String> _currentTimingPoints = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTimingPoints();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTimingPoints() async {
    try {
      final String data = await rootBundle.loadString('assets/timingpoints.txt');
      final List<TimingPointRoute> routes = _parseTimingPoints(data);
      
      if (mounted) {
        setState(() {
          _routes = routes;
          _availableRoutes = routes.map((route) => route.routeNumber).toList();
          if (_availableRoutes.isNotEmpty) {
            _selectedRoute = _availableRoutes.first;
            _updateDestinations();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading timing points: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<TimingPointRoute> _parseTimingPoints(String data) {
    final lines = data.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final Map<String, List<List<String>>> routeMap = {};

    for (final line in lines) {
      if (line.contains(' -> ')) {
        final parts = line.split(' -> ');
        if (parts.length == 2) {
          final routeNumber = parts[0].trim();
          final timingPoints = parts[1].split(',').map((point) => point.trim()).toList();
          
          if (!routeMap.containsKey(routeNumber)) {
            routeMap[routeNumber] = [];
          }
          routeMap[routeNumber]!.add(timingPoints);
        }
      }
    }

    final List<TimingPointRoute> routes = [];
    for (final entry in routeMap.entries) {
      final routeNumber = entry.key;
      final directions = entry.value;
      
      final direction1 = directions.isNotEmpty ? directions[0] : <String>[];
      final direction2 = directions.length > 1 ? directions[1] : <String>[];
      
      routes.add(TimingPointRoute(
        routeNumber: routeNumber,
        direction1Points: direction1,
        direction2Points: direction2,
      ));
    }

    // Sort routes by route number, with 23 and 24 at the bottom
    routes.sort((a, b) {
      // Put routes 23 and 24 at the bottom
      if (a.routeNumber == '23' || a.routeNumber == '24') {
        if (b.routeNumber == '23' || b.routeNumber == '24') {
          return a.routeNumber.compareTo(b.routeNumber);
        }
        return 1; // a comes after b
      }
      if (b.routeNumber == '23' || b.routeNumber == '24') {
        return -1; // a comes before b
      }
      // Normal sorting for other routes
      return a.routeNumber.compareTo(b.routeNumber);
    });
    return routes;
  }

  void _updateDestinations() {
    final selectedRouteData = _routes.firstWhere(
      (route) => route.routeNumber == _selectedRoute,
      orElse: () => TimingPointRoute(
        routeNumber: '',
        direction1Points: [],
        direction2Points: [],
      ),
    );

    final destinations = <String>[];
    if (selectedRouteData.direction1Points.isNotEmpty) {
      final destination = selectedRouteData.direction1Points.first;
      destinations.add(destination);
    }
    if (selectedRouteData.direction2Points.isNotEmpty) {
      final destination = selectedRouteData.direction2Points.first;
      destinations.add(destination);
    }

    setState(() {
      _availableDestinations = destinations;
      if (destinations.isNotEmpty) {
        _selectedDestination = destinations.first;
        _updateTimingPoints();
      } else {
        _selectedDestination = '';
        _currentTimingPoints = [];
      }
    });
  }

  void _updateTimingPoints() {
    final selectedRouteData = _routes.firstWhere(
      (route) => route.routeNumber == _selectedRoute,
      orElse: () => TimingPointRoute(
        routeNumber: '',
        direction1Points: [],
        direction2Points: [],
      ),
    );

    List<String> points = [];
    
    if (_selectedDestination.isNotEmpty) {
      // Determine which direction based on selected destination
      if (_availableDestinations.isNotEmpty && _selectedDestination == _availableDestinations[0]) {
        // Skip the first item (destination) and get only the timing points
        points = selectedRouteData.direction1Points.length > 1 
            ? selectedRouteData.direction1Points.sublist(1) 
            : [];
      } else if (_availableDestinations.length > 1 && _selectedDestination == _availableDestinations[1]) {
        // Skip the first item (destination) and get only the timing points
        points = selectedRouteData.direction2Points.length > 1 
            ? selectedRouteData.direction2Points.sublist(1) 
            : [];
      }
    }

    setState(() {
      _currentTimingPoints = points;
    });
  }

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones)
    if (screenWidth < 350) {
      return {
        'padding': 8.0,              // Reduced from 5% (~17.5px)
        'dropdownPadding': 6.0,      // Reduced from 4% (~14px)
        'listPadding': 6.0,          // Reduced from 4% (~14px)
        'headerPadding': 12.0,        // Reduced from 16
        'spacing': 16.0,             // Reduced from 24
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'padding': 10.0,
        'dropdownPadding': 8.0,
        'listPadding': 8.0,
        'headerPadding': 14.0,
        'spacing': 18.0,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'padding': 12.0,
        'dropdownPadding': 10.0,
        'listPadding': 10.0,
        'headerPadding': 15.0,
        'spacing': 20.0,
      };
    }
    // Regular phones
    else if (screenWidth < 600) {
      return {
        'padding': 14.0,
        'dropdownPadding': 12.0,
        'listPadding': 12.0,
        'headerPadding': 16.0,
        'spacing': 22.0,
      };
    }
    // Tablets
    else if (screenWidth < 900) {
      return {
        'padding': 16.0,
        'dropdownPadding': 14.0,
        'listPadding': 14.0,
        'headerPadding': 16.0,
        'spacing': 24.0,
      };
    }
    // Large tablets/desktop
    else {
      return {
        'padding': 18.0,             // Slightly more than original 5%
        'dropdownPadding': 16.0,     // Original 4% equivalent
        'listPadding': 16.0,         // Original 4% equivalent
        'headerPadding': 16.0,       // Original size
        'spacing': 24.0,             // Original size
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Timing Points'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                padding: EdgeInsets.all(sizes['padding']!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdowns Container (styled like Bills page)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(sizes['dropdownPadding']!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route Dropdown
                          Text(
                            'Route',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoute.isEmpty ? null : _selectedRoute,
                                isExpanded: true,
                                icon: Padding(
                                  padding: EdgeInsets.only(right: sizes['headerPadding']!),
                                  child: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryColor),
                                ),
                                items: _availableRoutes.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: sizes['headerPadding']!),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.directions_bus,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                                                                     Text(value),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue != _selectedRoute) {
                                    setState(() {
                                      _selectedRoute = newValue;
                                    });
                                    _updateDestinations();
                                  }
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Destination Dropdown
                          Text(
                            'Destination',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDestination.isEmpty ? null : _selectedDestination,
                                isExpanded: true,
                                icon: Padding(
                                  padding: EdgeInsets.only(right: sizes['headerPadding']!),
                                  child: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryColor),
                                ),
                                items: _availableDestinations.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: sizes['headerPadding']!),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              value,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue != _selectedDestination) {
                                    setState(() {
                                      _selectedDestination = newValue;
                                    });
                                    _updateTimingPoints();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: sizes['spacing']!),
                    
                    // Timing Points Display
                    Expanded(
                      child: _buildTimingPointsDisplay(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimingPointsDisplay() {
    final sizes = _getResponsiveSizes(context);
    
    if (_selectedRoute.isEmpty) {
      return const Center(
        child: Text(
          'Please select a route to view timing points',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (_currentTimingPoints.isEmpty) {
      return const Center(
        child: Text(
          'No timing points available for this route direction',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(sizes['headerPadding']!),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                topRight: Radius.circular(AppTheme.borderRadius),
              ),
            ),
                         child: Row(
               children: [
                 Icon(
                   Icons.route,
                   color: AppTheme.primaryColor,
                   size: 24,
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Route $_selectedRoute Timing Points',
                         style: const TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       if (_selectedDestination.isNotEmpty)
                         Row(
                           children: [
                             Icon(
                               Icons.arrow_forward,
                               color: AppTheme.primaryColor,
                               size: 16,
                             ),
                             const SizedBox(width: 4),
                             Expanded(
                               child: Text(
                                 'To: $_selectedDestination',
                                 style: TextStyle(
                                   fontSize: 14,
                                   color: AppTheme.primaryColor,
                                   fontWeight: FontWeight.w500,
                                 ),
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                               ),
                             ),
                           ],
                         ),
                     ],
                   ),
                 ),
               ],
             ),
          ),
          
                     // Timing points list
           Expanded(
             child: Scrollbar(
               controller: _scrollController,
               thumbVisibility: true,
               thickness: 6,
               radius: const Radius.circular(3),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(sizes['listPadding']!),
                 itemCount: _currentTimingPoints.length,
                 itemBuilder: (context, index) {
                 final point = _currentTimingPoints[index];
                 
                 return Container(
                   margin: const EdgeInsets.only(bottom: 8.0),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Number badge
                       Container(
                         width: 32,
                         height: 32,
                         decoration: BoxDecoration(
                           color: AppTheme.primaryColor,
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Center(
                           child: Text(
                             '${index + 1}',
                             style: const TextStyle(
                               color: Colors.white,
                               fontSize: 14,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ),
                       ),
                       const SizedBox(width: 16),
                       
                       // Timing point name
                       Expanded(
                         child: Container(
                           padding: const EdgeInsets.symmetric(vertical: 8.0),
                           child: Text(
                             point,
                             style: const TextStyle(fontSize: 15),
                             overflow: TextOverflow.visible,
                             softWrap: true,
                           ),
                         ),
                       ),
                     ],
                   ),
                 );
                 },
               ),
             ),
          ),
        ],
      ),
    );
  }
} 