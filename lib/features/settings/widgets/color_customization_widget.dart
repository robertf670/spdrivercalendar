import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../services/color_customization_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../theme/app_theme.dart';

class ColorCustomizationWidget extends StatefulWidget {
  final VoidCallback? onColorsChanged;

  const ColorCustomizationWidget({
    super.key,
    this.onColorsChanged,
  });

  @override
  State<ColorCustomizationWidget> createState() => _ColorCustomizationWidgetState();
}

class _ColorCustomizationWidgetState extends State<ColorCustomizationWidget> {
  Map<String, Color> _currentColors = {};
  bool _hasCustomColors = false;
  bool _isMFMarkedIn = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentColors();
    _loadMarkedInStatus();
  }

  Future<void> _loadMarkedInStatus() async {
    final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
    final markedInStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? 'Shift';
    setState(() {
      _isMFMarkedIn = markedInEnabled && (markedInStatus == 'M-F' || markedInStatus == '4 Day');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload marked in status when screen becomes visible again
    _loadMarkedInStatus();
  }

  void _loadCurrentColors() {
    setState(() {
      _currentColors = ColorCustomizationService.getShiftColors();
      // Ensure DAY_IN_LIEU color is always present
      if (!_currentColors.containsKey('DAY_IN_LIEU')) {
        _currentColors['DAY_IN_LIEU'] = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
      }
      // Ensure WFO color is always present
      if (!_currentColors.containsKey('WFO')) {
        _currentColors['WFO'] = ColorCustomizationService.getColorForShift('WFO');
      }
      // Ensure sick type colors are always present
      if (!_currentColors.containsKey('SICK_NORMAL')) {
        _currentColors['SICK_NORMAL'] = ColorCustomizationService.getColorForShift('SICK_NORMAL');
      }
      if (!_currentColors.containsKey('SICK_SELF_CERTIFIED')) {
        _currentColors['SICK_SELF_CERTIFIED'] = ColorCustomizationService.getColorForShift('SICK_SELF_CERTIFIED');
      }
      if (!_currentColors.containsKey('SICK_FORCE_MAJEURE')) {
        _currentColors['SICK_FORCE_MAJEURE'] = ColorCustomizationService.getColorForShift('SICK_FORCE_MAJEURE');
      }
      _hasCustomColors = ColorCustomizationService.hasCustomColors();
    });
  }

  Future<void> _showColorPicker(String shiftType, String shiftName) async {
    Color selectedColor = _currentColors[shiftType] ?? _currentColors['E']!;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose color for $shiftName shifts'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ColorCustomizationService.setShiftColor(shiftType, selectedColor);
                _loadCurrentColors();
                widget.onColorsChanged?.call();
                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetToDefaults() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Colors'),
          content: const Text('Are you sure you want to reset all colors to their default values?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await ColorCustomizationService.resetToDefaults();
      _loadCurrentColors();
      widget.onColorsChanged?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Colors reset to defaults'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.palette),
        title: const Text('Customize Shift Colors'),
        subtitle: Text(_hasCustomColors ? 'Custom colors active' : 'Using default colors'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show M-F or 4 Day marked in indicator if enabled
                if (_isMFMarkedIn)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FutureBuilder<String?>(
                            future: StorageService.getString(AppConstants.markedInStatusKey),
                            builder: (context, snapshot) {
                              final status = snapshot.data ?? 'Shift';
                              String message;
                              if (status == 'M-F') {
                                message = 'M-F Marked In is active. The "Work" color will be used for Monday-Friday shifts.';
                              } else if (status == '4 Day') {
                                message = '4 Day Marked In is active. The "Work" color will be used for Friday-Monday shifts.';
                              } else {
                                message = 'Marked In is active. Only relevant shift colors are shown.';
                              }
                              return Text(
                                message,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                // Color selection grid
                // Show Early, Late, Middle only when M-F marked in is NOT enabled
                if (!_isMFMarkedIn) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorTile('E', 'Early', _currentColors['E']!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildColorTile('L', 'Late', _currentColors['L']!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorTile('M', 'Middle', _currentColors['M']!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildColorTile('R', 'Rest', _currentColors['R']!),
                      ),
                    ],
                  ),
                ] else ...[
                  // When M-F marked in is enabled, only show Rest and Work
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorTile('R', 'Rest', _currentColors['R']!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildColorTile('W', 'Work', _currentColors['W'] ?? _currentColors['E']!),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Always show Work For Others and Day In Lieu color pickers side by side
                Row(
                  children: [
                    Expanded(
                      child: _buildColorTile('WFO', 'Work For Others', _currentColors['WFO'] ?? ColorCustomizationService.getColorForShift('WFO')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildColorTile('DAY_IN_LIEU', 'Day In Lieu', _currentColors['DAY_IN_LIEU'] ?? ColorCustomizationService.getColorForShift('DAY_IN_LIEU'), displayText: 'Lieu'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sick type color pickers
                const Text(
                  'Sick Day Colors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildColorTile('SICK_NORMAL', 'Normal Sick', _currentColors['SICK_NORMAL'] ?? ColorCustomizationService.getColorForShift('SICK_NORMAL'), displayText: 'Normal'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildColorTile('SICK_SELF_CERTIFIED', 'Self-Certified', _currentColors['SICK_SELF_CERTIFIED'] ?? ColorCustomizationService.getColorForShift('SICK_SELF_CERTIFIED'), displayText: 'Self'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildColorTile('SICK_FORCE_MAJEURE', 'Force Majeure', _currentColors['SICK_FORCE_MAJEURE'] ?? ColorCustomizationService.getColorForShift('SICK_FORCE_MAJEURE'), displayText: 'Force'),
                    ),
                    const SizedBox(width: 8),
                    // Empty space to maintain grid alignment
                    Expanded(child: Container()),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Reset button
                if (_hasCustomColors)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                
                // Info text
                const SizedBox(height: 8),
                Text(
                  'Tap any color to customize it. Changes will be applied immediately to all your events.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorTile(String shiftType, String shiftName, Color color, {String? displayText}) {
    // Use displayText if provided, otherwise use shiftType
    final circleText = displayText ?? shiftType;
    // Determine circle size based on text length for better fit
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final circleSize = circleText.length > 3 ? (isSmallScreen ? 44.0 : 48.0) : (isSmallScreen ? 40.0 : 44.0);
    final fontSize = circleText.length > 3 ? (isSmallScreen ? 12.0 : 14.0) : (isSmallScreen ? 14.0 : 16.0);
    
    return InkWell(
      onTap: () => _showColorPicker(shiftType, shiftName),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  circleText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shiftName,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 
