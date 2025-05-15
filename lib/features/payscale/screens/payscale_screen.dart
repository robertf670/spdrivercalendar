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

  @override
  void initState() {
    super.initState();
    _loadPayscaleData();
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

    // Extract column headers
    List<String> headers = _payscaleData![0].keys.toList();
    
    // Make the type column header more readable
    final labelMap = {
      'type': 'Payment Type',
      'year1+2': 'Year 1-2',
      'year3+4': 'Year 3-4',
      'year5': 'Year 5',
      'year6': 'Year 6+',
    };
    
    // Format payment types to be more readable
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  headingRowColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
                    },
                  ),
                  border: TableBorder.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    width: 1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columns: headers.map((header) {
                    final label = labelMap[header] ?? header;
                    return DataColumn(
                      label: Text(label),
                    );
                  }).toList(),
                  rows: _payscaleData!.map((row) {
                    return DataRow(
                      cells: headers.map((header) {
                        String cellValue = row[header] ?? '';
                        
                        // Format the payment type name
                        if (header == 'type') {
                          cellValue = paymentTypeFormatMap[cellValue.toLowerCase()] ?? cellValue;
                        }
                        // Format currency values
                        else if (headers.indexOf(header) > 0) {
                          // Try to parse as double to format as currency
                          try {
                            final value = double.parse(cellValue);
                            cellValue = '€${value.toStringAsFixed(2)}';
                          } catch (e) {
                            // Keep original if not a valid number
                          }
                        }
                        
                        return DataCell(Text(cellValue));
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Note: All rates are in Euro (€)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
} 