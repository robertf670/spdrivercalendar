import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/pay_scale_service.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Widget that calculates and displays spread over payment estimate only
/// (time over 10 hours multiplied by year level rate)
class EarningsCalculatorCard extends StatefulWidget {
  final Duration totalWorkTime;
  final Duration thisWeekSpreadTime;
  final Duration lastWeekSpreadTime;
  final int overtimeShifts;
  final Duration overtimeDuration;

  const EarningsCalculatorCard({
    super.key,
    required this.totalWorkTime,
    required this.thisWeekSpreadTime,
    required this.lastWeekSpreadTime,
    this.overtimeShifts = 0,
    this.overtimeDuration = const Duration(),
  });

  @override
  State<EarningsCalculatorCard> createState() => _EarningsCalculatorCardState();
}

class _EarningsCalculatorCardState extends State<EarningsCalculatorCard> {
  String? _selectedYearLevel;
  bool _isLoading = true;
  Map<String, double>? _payRates;

  @override
  void initState() {
    super.initState();
    _loadPayRates();
    _loadSavedYearLevel();
  }

  Future<void> _loadPayRates() async {
    try {
      // Load rates for each year level
      final rates = <String, double>{};
      for (final level in PayScaleService.getYearLevelOptions()) {
        final rate = await PayScaleService.getSpreadRate(level);
        if (rate != null) {
          rates[level] = rate;
        }
      }
      setState(() {
        _payRates = rates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedYearLevel() async {
    final saved = await StorageService.getString('selected_year_level');
    if (saved != null && mounted) {
      setState(() {
        _selectedYearLevel = saved;
      });
    } else if (mounted) {
      // Default to year1+2 if nothing saved
      setState(() {
        _selectedYearLevel = 'year1+2';
      });
    }
  }

  Future<void> _saveYearLevel(String level) async {
    await StorageService.saveString('selected_year_level', level);
  }

  double? _calculateEarnings(Duration spreadTime) {
    if (_selectedYearLevel == null || _payRates == null) return null;

    final spreadRate = _payRates![_selectedYearLevel!];
    if (spreadRate == null) return null;

    // Calculate spread over payment: spreadTime is already the time over 10 hours
    // (calculated by _calculateSpreadPay which subtracts 10 hours from total spread time)
    final spreadPayHours = spreadTime.inHours + 
        (spreadTime.inMinutes.remainder(60) / 60.0);
    final spreadPayAmount = spreadPayHours * spreadRate;

    return spreadPayAmount;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spread Over Payment',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                DropdownButton<String>(
                  value: _selectedYearLevel,
                  hint: const Text('Year Level'),
                  items: PayScaleService.getYearLevelOptions().map((level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(PayScaleService.getYearLevelDisplayName(level)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedYearLevel = value;
                      });
                      _saveYearLevel(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedYearLevel != null && _payRates != null) ...[
              _buildEarningsRow(
                'This Week',
                widget.thisWeekSpreadTime,
                _calculateEarnings(widget.thisWeekSpreadTime),
                Colors.indigo,
              ),
              const SizedBox(height: 12),
              _buildEarningsRow(
                'Last Week',
                widget.lastWeekSpreadTime,
                _calculateEarnings(widget.lastWeekSpreadTime),
                Colors.deepPurple,
              ),
              const SizedBox(height: 12),
              Text(
                'Note: This calculates spread over payment only (time over 10 hours). '
                'This does NOT include basic pay, shift premiums, or other earnings. '
                'For total earnings, you will need to calculate separately.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              const Text(
                'Unable to calculate spread pay. Please select a year level.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            _buildStatRow('This Week Spread', _formatDuration(widget.thisWeekSpreadTime)),
            _buildStatRow('Last Week Spread', _formatDuration(widget.lastWeekSpreadTime)),
            if (widget.overtimeShifts > 0)
              _buildStatRow(
                'Overtime Shifts',
                '${widget.overtimeShifts}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsRow(String label, Duration spreadTime, double? earnings, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              Text(
                _formatDuration(spreadTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Text(
            earnings != null ? '~€${earnings.toStringAsFixed(2)}' : '~€0.00',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}

