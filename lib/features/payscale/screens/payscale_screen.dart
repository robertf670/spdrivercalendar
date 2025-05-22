import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class PayscaleScreen extends StatefulWidget {
  const PayscaleScreen({Key? key}) : super(key: key);

  @override
  _PayscaleScreenState createState() => _PayscaleScreenState();
}

class _PayscaleScreenState extends State<PayscaleScreen> {
  List<Map<String, dynamic>>? _payscaleData;
  bool _isLoading = true;
  String? _errorMessage;

  // Scroll controllers for synchronized scrolling
  final ScrollController _verticalController1 = ScrollController();
  final ScrollController _verticalController2 = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  // Flag to prevent infinite loop when syncing scrolls
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _loadPayscaleData();
    
    // Set up scroll synchronization
    _verticalController1.addListener(_syncScrollVertical1);
    _verticalController2.addListener(_syncScrollVertical2);
  }

  // Sync scroll from first column to second column
  void _syncScrollVertical1() {
    if (!_isScrolling && _verticalController1.hasClients && _verticalController2.hasClients) {
      _isScrolling = true;
      _verticalController2.jumpTo(_verticalController1.offset);
      _isScrolling = false;
    }
  }

  // Sync scroll from second column to first column
  void _syncScrollVertical2() {
    if (!_isScrolling && _verticalController1.hasClients && _verticalController2.hasClients) {
      _isScrolling = true;
      _verticalController1.jumpTo(_verticalController2.offset);
      _isScrolling = false;
    }
  }

  @override
  void dispose() {
    _verticalController1.removeListener(_syncScrollVertical1);
    _verticalController2.removeListener(_syncScrollVertical2);
    _verticalController1.dispose();
    _verticalController2.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPayscaleData() async {
    try {
      // Load the CSV data
      final String csvData = await rootBundle.loadString('pay/payscale.csv');
      
      // Parse the CSV
      List<Map<String, dynamic>> parsedData = [];
      
      // Split by lines and get headers
      List<String> lines = csvData.split('\n');
      List<String> headers = lines[0].split(',');
      
      // Process each data row
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        List<String> values = lines[i].split(',');
        Map<String, dynamic> row = {};
        
        for (int j = 0; j < headers.length && j < values.length; j++) {
          row[headers[j].trim()] = values[j].trim();
        }
        
        if (row.isNotEmpty) {
          parsedData.add(row);
        }
      }
      
      setState(() {
        _payscaleData = parsedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading pay scales: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Scales'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Data',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPayscaleTable(),
    );
  }

  Widget _buildPayscaleTable() {
    if (_payscaleData == null || _payscaleData!.isEmpty) {
      return const Center(child: Text('No pay scale data available'));
    }

    List<String> allHeaders = _payscaleData![0].keys.toList();
    String fixedColumnKey = 'type';
    List<String> scrollableColumnHeaders = allHeaders.where((h) => h != fixedColumnKey).toList();

    final labelMap = {
      'type': 'Payment Type',
      'year1+2': 'Year 1-2',
      'year3+4': 'Year 3-4',
      'year5': 'Year 5',
      'year6': 'Year 6+',
    };

    final paymentTypeFormatMap = {
      'basicdaily': 'Basic Daily Rate',
      'shiftdaily': 'Shift Premium (Daily)',
      'weeklyexlsunday': 'Weekly Rate (Excl. Sunday)',
      'weeklyinclsunday': 'Weekly Rate (Incl. Sunday)',
      'workingrestday(mon-sat)': 'Rest Day Rate (Mon-Sat)',
      'workingrestday(sun)': 'Rest Day Rate (Sunday)',
      'bankholiday': 'Bank Holiday Rate',
      'overtimeweekday(hourly)': 'Overtime Rate (Weekday)',
      'overtimesunday(hourly)': 'Overtime Rate (Sunday)',
      'overtimebankholiday(hourly)': 'Overtime Rate (Bank Holiday)',
      'privatehireweekday(hourly)': 'Private Hire Rate (Weekday)',
      'privatehiresunday(hourly)': 'Private Hire Rate (Sunday)',
      'privatehirebankholiday(hourly)': 'Private Hire Rate (Bank Holiday)',
      'spreadover(hourly)': 'Spreadover Rate (Hourly)',
    };

    final cellPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    final headerTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 14,
    );
    final cellTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
      fontSize: 14,
    );
    final headerBackgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2);

    // Define colors for alternating rows
    final cardBackgroundColor = Theme.of(context).cardColor;
    final oddRowOverlayColor = (Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withOpacity(0.05) 
        : Colors.black.withOpacity(0.03));

    // Fixed row height for consistency
    const double rowHeight = 60.0;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Pay Scales',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'The following rates apply based on length of service:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              color: cardBackgroundColor,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // Header row (frozen at top)
                  Container(
                    color: headerBackgroundColor,
                    height: rowHeight,
                    child: Row(
                      children: [
                        // Fixed header column
                        Container(
                          width: 190,
                          padding: cellPadding,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5), width: 1),
                              bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3), width: 1),
                            ),
                          ),
                          child: Text(
                            labelMap[fixedColumnKey] ?? fixedColumnKey,
                            style: headerTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Scrollable headers
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: scrollableColumnHeaders.map((header) {
                                final label = labelMap[header] ?? header;
                                return Container(
                                  width: 120,
                                  padding: cellPadding,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3), width: 1),
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: headerTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table body with synchronized scrolling
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fixed left column
                        SizedBox(
                          width: 190,
                          child: GestureDetector(
                            // Make the left column also respond to horizontal swipes
                            onHorizontalDragUpdate: (details) {
                              if (_horizontalScrollController.hasClients) {
                                _horizontalScrollController.position.jumpTo(
                                  _horizontalScrollController.position.pixels - details.delta.dx
                                );
                              }
                            },
                            child: ListView.builder(
                              controller: _verticalController1,
                              itemCount: _payscaleData!.length,
                              itemExtent: rowHeight,
                              physics: const ClampingScrollPhysics(),
                              itemBuilder: (context, index) {
                                Map<String, dynamic> row = _payscaleData![index];
                                String cellValue = row[fixedColumnKey] ?? '';
                                cellValue = paymentTypeFormatMap[cellValue.toLowerCase()] ?? cellValue;
                                
                                return Container(
                                  height: rowHeight,
                                  decoration: BoxDecoration(
                                    color: index.isOdd 
                                      ? oddRowOverlayColor 
                                      : Colors.transparent,
                                    border: Border(
                                      right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5), width: 1),
                                      bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
                                    ),
                                  ),
                                  padding: cellPadding,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    cellValue, 
                                    style: cellTextStyle, 
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Scrollable data columns
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: scrollableColumnHeaders.length * 120.0,
                              child: ListView.builder(
                                controller: _verticalController2,
                                itemCount: _payscaleData!.length,
                                itemExtent: rowHeight,
                                physics: const ClampingScrollPhysics(),
                                itemBuilder: (context, rowIndex) {
                                  Map<String, dynamic> row = _payscaleData![rowIndex];
                                  
                                  return Container(
                                    height: rowHeight,
                                    decoration: BoxDecoration(
                                      color: rowIndex.isOdd 
                                        ? oddRowOverlayColor 
                                        : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: scrollableColumnHeaders.map((header) {
                                        String cellValue = row[header] ?? '';
                                        try {
                                          final value = double.parse(cellValue);
                                          cellValue = '€${value.toStringAsFixed(2)}';
                                        } catch (e) {
                                          // Keep original
                                        }
                                        return Container(
                                          width: 120,
                                          padding: cellPadding,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            cellValue, 
                                            style: cellTextStyle,
                                            textAlign: TextAlign.right,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for the fixed column with synchronized scrolling
class ScrollableColumn extends StatelessWidget {
  final ScrollController verticalController;
  final int itemCount;
  final double itemHeight;
  final Widget Function(BuildContext, int) itemBuilder;

  const ScrollableColumn({
    Key? key,
    required this.verticalController,
    required this.itemCount,
    required this.itemHeight,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // No need to handle scroll notifications
        // as we are using the same controller
        return false;
      },
      child: ListView.builder(
        controller: verticalController,
        itemCount: itemCount,
        itemExtent: itemHeight,
        physics: const ClampingScrollPhysics(),
        itemBuilder: itemBuilder,
      ),
    );
  }
} 