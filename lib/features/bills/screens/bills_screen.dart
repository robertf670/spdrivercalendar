import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'dart:convert';

class BillsScreen extends StatefulWidget {
  const BillsScreen({Key? key}) : super(key: key);

  @override
  _BillsScreenState createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String _selectedDayType = 'M-F';
  String _selectedZone = 'Zone 1';
  bool _isLoading = false;
  List<String> _headers = [];
  List<List<String>> _rows = [];
  String? _errorMessage;
  
  // For fixed column implementation
  String _shiftColumnHeader = "";
  List<String> _shiftColumnData = [];
  List<String> _scrollableHeaders = [];
  List<List<String>> _scrollableRows = [];
  
  // Horizontal scroll controllers with sync lock
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _dataScrollController = ScrollController();
  bool _isScrollingHeader = false;
  bool _isScrollingData = false;
  
  // Vertical scroll controllers
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  bool _isScrollingLeftVertical = false;
  bool _isScrollingRightVertical = false;

  @override
  void initState() {
    super.initState();
    _loadCsvData();
    
    // Horizontal sync: data to header
    _dataScrollController.addListener(() {
      if (!_isScrollingData && !_isScrollingHeader) {
        _isScrollingData = true;
        _headerScrollController.jumpTo(_dataScrollController.offset);
        _isScrollingData = false;
      }
    });
    
    // Horizontal sync: header to data
    _headerScrollController.addListener(() {
      if (!_isScrollingHeader && !_isScrollingData) {
        _isScrollingHeader = true;
        _dataScrollController.jumpTo(_headerScrollController.offset);
        _isScrollingHeader = false;
      }
    });
    
    // Vertical sync: left to right
    _leftVerticalController.addListener(() {
      if (!_isScrollingLeftVertical && !_isScrollingRightVertical) {
        _isScrollingLeftVertical = true;
        _rightVerticalController.jumpTo(_leftVerticalController.offset);
        _isScrollingLeftVertical = false;
      }
    });
    
    // Vertical sync: right to left
    _rightVerticalController.addListener(() {
      if (!_isScrollingRightVertical && !_isScrollingLeftVertical) {
        _isScrollingRightVertical = true;
        _leftVerticalController.jumpTo(_rightVerticalController.offset);
        _isScrollingRightVertical = false;
      }
    });
  }
  
  @override
  void dispose() {
    _headerScrollController.dispose();
    _dataScrollController.dispose();
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    super.dispose();
  }

  Future<void> _loadCsvData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Construct the filename based on selected values
      final zoneNumber = _selectedZone.replaceAll('Zone ', '');
      // Format filenames with correct capitalization
      String dayTypeForFilename = _selectedDayType;
      if (_selectedDayType == 'Sat') {
        dayTypeForFilename = 'SAT';
      } else if (_selectedDayType == 'Sun') {
        dayTypeForFilename = 'SUN';
      }
      final filename = '${dayTypeForFilename}_DUTIES_PZ$zoneNumber.csv';
      final path = 'assets/$filename';
      
      // Load the CSV content
      final String csvData = await rootBundle.loadString(path);
      final List<String> lines = csvData.split('\n');

      if (lines.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'CSV file is empty';
        });
        return;
      }

      // Parse headers (first line) and format them
      final originalHeaders = _parseCsvLine(lines[0]);
      // Format headers for better display
      final headers = originalHeaders.map((header) => _formatHeaderText(header)).toList();
      
      // Find the index of the "duty" column to remove it
      int dutyColumnIndex = -1;
      for (int i = 0; i < originalHeaders.length; i++) {
        if (originalHeaders[i].toLowerCase() == 'duty') {
          dutyColumnIndex = i;
          break;
        }
      }
      
      // Remove duty column from headers if found
      if (dutyColumnIndex != -1) {
        headers.removeAt(dutyColumnIndex);
      }
      
      // Parse data rows (remaining lines)
      final rows = <List<String>>[];
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) {
          final rowData = _parseCsvLine(lines[i]);
          
          // Remove duty column from this row if applicable
          if (dutyColumnIndex != -1 && dutyColumnIndex < rowData.length) {
            rowData.removeAt(dutyColumnIndex);
          }
          
          rows.add(rowData);
        }
      }

      // Extract fixed shift column (assuming it's the first column after removing duty)
      String shiftHeader = "";
      final shiftColumnData = <String>[];
      final scrollableHeaders = <String>[];
      final scrollableRows = <List<String>>[];
      
      if (headers.isNotEmpty) {
        // Get the shift column header (first column)
        shiftHeader = headers[0];
        
        // Check for empty or missing columns
        List<int> emptyColumnIndices = [];
        for (int i = 1; i < headers.length; i++) {
          bool isEmpty = true;
          
          // Check if this column is empty or has only "nan" values
          for (final row in rows) {
            if (i < row.length && 
                row[i].trim().isNotEmpty && 
                row[i].toLowerCase() != "nan") {
              isEmpty = false;
              break;
            }
          }
          
          if (isEmpty) {
            emptyColumnIndices.add(i);
          }
        }
        
        // Add non-empty headers to scrollable headers
        for (int i = 1; i < headers.length; i++) {
          if (!emptyColumnIndices.contains(i)) {
            scrollableHeaders.add(headers[i]);
          }
        }
        
        // Extract shift column data and remaining data
        for (final row in rows) {
          if (row.isNotEmpty) {
            shiftColumnData.add(row[0]);
            
            if (row.length > 1) {
              // Add only non-empty columns to scrollable rows
              List<String> filteredRow = [];
              for (int i = 1; i < row.length; i++) {
                if (!emptyColumnIndices.contains(i)) {
                  filteredRow.add(row[i]);
                }
              }
              scrollableRows.add(filteredRow);
            } else {
              scrollableRows.add([]);
            }
          } else {
            shiftColumnData.add('');
            scrollableRows.add([]);
          }
        }
      }

      setState(() {
        _headers = headers;
        _rows = rows;
        _shiftColumnHeader = shiftHeader;
        _shiftColumnData = shiftColumnData;
        _scrollableHeaders = scrollableHeaders;
        _scrollableRows = scrollableRows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data: ${e.toString()}';
      });
    }
  }

  // Simple CSV line parser
  List<String> _parseCsvLine(String line) {
    // This handles basic CSV parsing - you might need a more robust parser for complex CSVs
    return line.split(',').map((cell) => cell.trim()).toList();
  }

  // Helper method to format header text
  String _formatHeaderText(String header) {
    if (header.isEmpty) return '';
    
    // Convert to lowercase first to handle all-caps headers
    String formattedHeader = header.toLowerCase();
    
    // Replace underscores with spaces
    formattedHeader = formattedHeader.replaceAll('_', ' ');
    
    // First split by known compound word segments
    // The order matters - we need to check longer patterns first
    final wordMappings = {
      'breaklocation': 'break location',
      'startbreak': 'start break',
      'finishbreak': 'finish break',
      'breakreport': 'break report',
      'signoff': 'sign off',
      'finishlocation': 'finish location',
      'startlocation': 'start location',
      'location': 'location',    // Handle any remaining "location"
      'break': 'break',          // Handle any remaining "break"
      'report': 'report',        // Handle any remaining "report"
      'finish': 'finish',        // Handle any remaining "finish"
      'start': 'start',          // Handle any remaining "start"
      'sign': 'sign',            // Handle any remaining "sign"
      'off': 'off',              // Handle any remaining "off"
    };
    
    // Process replacements from longest to shortest to avoid partial replacements
    final sortedKeys = wordMappings.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (final key in sortedKeys) {
      formattedHeader = formattedHeader.replaceAll(key, wordMappings[key]!);
    }
    
    // Cleanup: handle any double spaces that might have been created
    formattedHeader = formattedHeader.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Generic camelCase or PascalCase splitting (for other potential headers)
    formattedHeader = formattedHeader.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}'
    );
    
    // Capitalize each word
    List<String> words = formattedHeader.split(' ');
    words = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : '');
    }).toList();
    
    return words.join(' ');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdowns Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Type Dropdown
                    const Text(
                      'Day Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDayType,
                          isExpanded: true,
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 16.0),
                            child: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryColor),
                          ),
                          items: ['M-F', 'Sat', 'Sun'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.work,
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
                            if (newValue != null && newValue != _selectedDayType) {
                              setState(() {
                                _selectedDayType = newValue;
                              });
                              _loadCsvData();
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Zone Dropdown
                    const Text(
                      'Zone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedZone,
                          isExpanded: true,
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 16.0),
                            child: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryColor),
                          ),
                          items: ['Zone 1', 'Zone 3', 'Zone 4'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.map,
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
                            if (newValue != null && newValue != _selectedZone) {
                              setState(() {
                                _selectedZone = newValue;
                              });
                              _loadCsvData();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // CSV Data Display Section
              Expanded(
                child: _buildCsvDataDisplay(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCsvDataDisplay() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade800,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCsvData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade800,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_headers.isEmpty || _rows.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
    }

    // Column width constants - SIGNIFICANTLY INCREASED for better content visibility
    const double fixedColumnWidth = 80;  // Increased from 50 to 80 for shift IDs
    const double dataColumnWidth = 110;  // Increased from 70 to 110 for locations/times
    const double headerHeight = 60;  // Kept same for wrapped text

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Table title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Schedule Data for ${_selectedDayType}, ${_selectedZone}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1, thickness: 1),
          
          // Headers row with fixed and scrollable sections
          SizedBox(
            height: headerHeight,
            child: Row(
              children: [
                // Fixed shift column header
                Container(
                  width: fixedColumnWidth,
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  child: Center(
                    child: Text(
                      _shiftColumnHeader,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Divider between fixed and scrollable columns
                Container(
                  width: 1,
                  height: headerHeight,
                  color: Colors.grey.shade300,
                ),
                // Scrollable headers
                Expanded(
                  child: Container(
                    color: Colors.grey.shade200,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _headerScrollController,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: _scrollableHeaders.map((header) {
                          return Container(
                            width: dataColumnWidth,
                            height: headerHeight,
                            padding: const EdgeInsets.all(4),
                            child: Center(
                              child: Text(
                                header,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,  // Reduced from 11 to 10 for better fit
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 4,  // Increased from 3 to 4 lines
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table data - split into fixed and scrollable sections
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed column (shift numbers)
                SingleChildScrollView(
                  controller: _leftVerticalController,
                  child: Column(
                    children: List.generate(_shiftColumnData.length, (index) {
                      final isEvenRow = index % 2 == 0;
                      return Container(
                        width: fixedColumnWidth,
                        color: isEvenRow ? Colors.white : Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          _shiftColumnData[index].toLowerCase() == "nan" ? "W/O" : _shiftColumnData[index],
                          style: TextStyle(
                            fontWeight: FontWeight.w500, // Make shift column slightly bolder
                            color: Colors.grey.shade800,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ),
                ),
                
                // Divider between fixed and scrollable columns
                Container(
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                
                // Scrollable data section
                Expanded(
                  child: SingleChildScrollView(
                    controller: _rightVerticalController,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _dataScrollController,
                      child: SizedBox(
                        width: _scrollableHeaders.length * dataColumnWidth,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _scrollableRows.length,
                          itemBuilder: (context, rowIndex) {
                            final isEvenRow = rowIndex % 2 == 0;
                            final row = _scrollableRows[rowIndex];
                            
                            return Container(
                              color: isEvenRow ? Colors.white : Colors.grey.shade50,
                              child: Row(
                                children: List.generate(
                                  _scrollableHeaders.length,
                                  (colIndex) => Container(
                                    width: dataColumnWidth,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text(
                                      colIndex < row.length ? (row[colIndex].toLowerCase() == "nan" ? "W/O" : row[colIndex]) : '',
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 11,  // Reduced from 12 to 11 to fit more content
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,  // Allow 2 lines instead of 1
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table footer with row count
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_rows.length} rows',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 