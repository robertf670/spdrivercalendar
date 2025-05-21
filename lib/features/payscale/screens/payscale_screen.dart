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
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPayscaleData();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
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
        title: const Text('Dublin Bus Pay Scales'),
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

    final oddRowColor = MaterialStateProperty.resolveWith<Color?>((states) => oddRowOverlayColor);
    // Even rows will use the default DataTable row color (which should be transparent over the Card background)
    final evenRowColor = MaterialStateProperty.resolveWith<Color?>((states) => Colors.transparent);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dublin Bus Driver Pay Scales',
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
                borderRadius: BorderRadius.circular(AppTheme.borderRadius), // This radius affects corner clipping
              ),
              color: cardBackgroundColor, // Explicitly set card background
              margin: EdgeInsets.zero, // Card is already in Expanded with outer Padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed Column (Payment Type)
                  SizedBox(
                    width: 190,
                    child: Column(
                      children: [
                        // Header for fixed column
                        Container(
                          height: 48,
                          color: headerBackgroundColor,
                          alignment: Alignment.centerLeft,
                          padding: cellPadding,
                          child: Text(
                            labelMap[fixedColumnKey] ?? fixedColumnKey,
                            style: headerTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Data rows for fixed column
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              // Sync the other scroll controller when this one scrolls
                              if (scrollInfo.depth == 0) {
                                _verticalScrollController.jumpTo(scrollInfo.metrics.pixels);
                              }
                              return false; // Don't stop the notification bubble up
                            },
                            child: ListView.builder(
                              itemCount: _payscaleData!.length,
                              itemBuilder: (context, rowIndex) {
                                Map<String, dynamic> row = _payscaleData![rowIndex];
                                String cellValue = row[fixedColumnKey] ?? '';
                                cellValue = paymentTypeFormatMap[cellValue.toLowerCase()] ?? cellValue;
                                
                                return Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: rowIndex.isOdd 
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
                                    overflow: TextOverflow.visible,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Columns
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: scrollableColumnHeaders.length * 120.0,
                        child: Column(
                          children: [
                            // Headers for scrollable columns
                            Container(
                              height: 48,
                              color: headerBackgroundColor,
                              child: Row(
                                children: scrollableColumnHeaders.map((header) {
                                  final label = labelMap[header] ?? header;
                                  return SizedBox(
                                    width: 120, 
                                    child: Padding(
                                      padding: cellPadding,
                                      child: Text(
                                        label, 
                                        style: headerTextStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Data cells for scrollable columns
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification scrollInfo) {
                                  // Only respond to scroll notifications from the direct child
                                  if (scrollInfo.depth == 0) {
                                    // Keep the fixed column in sync with this scrolling
                                    _verticalScrollController.jumpTo(scrollInfo.metrics.pixels);
                                  }
                                  return false; // Don't stop the notification bubble up
                                },
                                child: ListView.builder(
                                  controller: _verticalScrollController,
                                  itemCount: _payscaleData!.length,
                                  itemBuilder: (context, rowIndex) {
                                    Map<String, dynamic> row = _payscaleData![rowIndex];
                                    
                                    return Container(
                                      height: 50,
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
                                          if (scrollableColumnHeaders.indexOf(header) >= 0) {
                                            try {
                                              final value = double.parse(cellValue);
                                              cellValue = '€${value.toStringAsFixed(2)}';
                                            } catch (e) {
                                              // Keep original
                                            }
                                          }
                                          return SizedBox(
                                            width: 120, 
                                            child: Padding(
                                              padding: cellPadding,
                                              child: Text(
                                                cellValue, 
                                                style: cellTextStyle, 
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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