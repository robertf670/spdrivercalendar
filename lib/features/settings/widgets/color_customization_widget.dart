import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../services/color_customization_service.dart';
import '../../../theme/app_theme.dart';

class ColorCustomizationWidget extends StatefulWidget {
  final VoidCallback? onColorsChanged;

  const ColorCustomizationWidget({
    Key? key,
    this.onColorsChanged,
  }) : super(key: key);

  @override
  State<ColorCustomizationWidget> createState() => _ColorCustomizationWidgetState();
}

class _ColorCustomizationWidgetState extends State<ColorCustomizationWidget> {
  Map<String, Color> _currentColors = {};
  bool _hasCustomColors = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentColors();
  }

  void _loadCurrentColors() {
    setState(() {
      _currentColors = ColorCustomizationService.getShiftColors();
      _hasCustomColors = ColorCustomizationService.hasCustomColors();
    });
  }

  Future<void> _showColorPicker(String shiftType, String shiftName) async {
    Color selectedColor = _currentColors[shiftType]!;
    
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
                // Color selection grid
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

  Widget _buildColorTile(String shiftType, String shiftName, Color color) {
    return InkWell(
      onTap: () => _showColorPicker(shiftType, shiftName),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
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
                  shiftType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shiftName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 
