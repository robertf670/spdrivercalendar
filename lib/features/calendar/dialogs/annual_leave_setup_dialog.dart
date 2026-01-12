import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/services/annual_leave_service.dart';

class AnnualLeaveSetupDialog extends StatefulWidget {
  const AnnualLeaveSetupDialog({super.key});

  @override
  State<AnnualLeaveSetupDialog> createState() => _AnnualLeaveSetupDialogState();
}

class _AnnualLeaveSetupDialogState extends State<AnnualLeaveSetupDialog> {
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
      await AnnualLeaveService.setBalance(0);
      await AnnualLeaveService.markAsSet();
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
      await AnnualLeaveService.setBalance(value);
      await AnnualLeaveService.markAsSet();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Annual leave balance set to $value'),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.beach_access, color: primaryColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Set Annual Leave Balance',
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
              'How many annual leave days do you currently have?',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Only future holidays will count toward used days. Past holidays are ignored.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
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
                TextButton(
                  onPressed: _isLoading ? null : () {
                    // Set to 0 if user cancels without entering
                    AnnualLeaveService.setBalance(0);
                    AnnualLeaveService.markAsSet();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Skip (Set to 0)'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveBalance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
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
