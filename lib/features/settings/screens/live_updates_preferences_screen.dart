import 'package:flutter/material.dart';
import '../../../services/user_preferences_service.dart';
import '../../../theme/app_theme.dart';

class LiveUpdatesPreferencesScreen extends StatefulWidget {
  const LiveUpdatesPreferencesScreen({super.key});

  @override
  LiveUpdatesPreferencesScreenState createState() => LiveUpdatesPreferencesScreenState();
}

class LiveUpdatesPreferencesScreenState extends State<LiveUpdatesPreferencesScreen> {
  List<String> _preferredRoutes = [];
  bool _showAllUpdates = false;
  bool _isLoading = true;
  
  final List<String> _availableRoutes = UserPreferencesService.availableRoutes;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final routes = await UserPreferencesService.getPreferredRoutes();
      final showAll = await UserPreferencesService.getShowAllUpdates();
      
      setState(() {
        _preferredRoutes = List<String>.from(routes);
        _showAllUpdates = showAll;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      await UserPreferencesService.setPreferredRoutes(_preferredRoutes);
      await UserPreferencesService.setShowAllUpdates(_showAllUpdates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetToDefaults() async {
    await UserPreferencesService.resetToDefaults();
    _loadPreferences();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences reset to defaults'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Updates Preferences'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Updates Preferences'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Show All Updates'),
                      subtitle: const Text('See updates for all routes, not just your preferred ones'),
                      value: _showAllUpdates,
                      onChanged: (value) {
                        setState(() {
                          _showAllUpdates = value;
                        });
                        _savePreferences();
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Preferred Routes
            if (!_showAllUpdates) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Preferred Routes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_preferredRoutes.length} selected',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll only see live updates that affect these routes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Selected routes display
                      if (_preferredRoutes.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _preferredRoutes.map((route) => Chip(
                            label: Text(route),
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            deleteIcon: Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            onDeleted: () {
                              setState(() {
                                _preferredRoutes.remove(route);
                              });
                              _savePreferences();
                            },
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _showRouteSelector,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Routes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRouteSelector() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9 < 500
              ? MediaQuery.of(context).size.width * 0.9
              : 500,
          height: MediaQuery.of(context).size.height * 0.45 < 360
              ? MediaQuery.of(context).size.height * 0.45
              : 360,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Select Routes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final textScale = MediaQuery.textScalerOf(context)
                        .scale(1.0)
                        .clamp(1.0, 3.0);
                    final routeGridAspect = (2.0 / textScale).clamp(0.65, 2.5);
                    return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: routeGridAspect,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _availableRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _availableRoutes[index];
                    final isSelected = _preferredRoutes.contains(route);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _preferredRoutes.remove(route);
                          } else {
                            _preferredRoutes.add(route);
                          }
                        });
                        _savePreferences();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? AppTheme.primaryColor 
                            : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                              ? AppTheme.primaryColor 
                              : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            route,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 