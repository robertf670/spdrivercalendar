import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/services/days_in_lieu_service.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';

class DaysInLieuSetupDialog extends StatefulWidget {
  const DaysInLieuSetupDialog({super.key});

  @override
  State<DaysInLieuSetupDialog> createState() => _DaysInLieuSetupDialogState();
}

class _DaysInLieuSetupDialogState extends State<DaysInLieuSetupDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBalance() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      // User entered nothing, set to 0
      await DaysInLieuService.setBalance(0);
      await DaysInLieuService.markAsSet();
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final value = int.tryParse(text);
    if (value == null || value < 0) {
      // Invalid input, show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number (0 or greater)'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DaysInLieuService.setBalance(value);
      await DaysInLieuService.markAsSet();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Days in lieu balance set to $value'),
            backgroundColor: ColorCustomizationService.getColorForShift('DAY_IN_LIEU'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving balance. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dayInLieuColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_available, color: dayInLieuColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Set Days In Lieu Balance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'How many days in lieu do you currently have?',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Number of days',
                hintText: 'Enter 0 if you have none',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
              autofocus: true,
              onSubmitted: (_) => _saveBalance(),
            ),
            const SizedBox(height: 8),
            Text(
              'You can update this anytime in Settings > Holidays & Leave',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      // Set to 0 if user cancels without entering
                      DaysInLieuService.setBalance(0);
                      DaysInLieuService.markAsSet();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Skip (Set to 0)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveBalance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dayInLieuColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
