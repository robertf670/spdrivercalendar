import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class PayscaleScreen extends StatefulWidget {
  const PayscaleScreen({super.key});

  @override
  PayscaleScreenState createState() => PayscaleScreenState();
}

class PayscaleScreenState extends State<PayscaleScreen> {
  List<Map<String, dynamic>>? _payscaleData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayscaleData();
  }

  static const String _coreHrUrl =
      'https://my.corehr.com/pls/coreportal_dbp/cp_por_public_main_page.display_login_page';

  Future<void> _launchCoreHr(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Uri uri = Uri.parse(_coreHrUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Could not open People XD'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error opening link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      body: SafeArea(
        child: _isLoading
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
      ),
    );
  }

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones) - ULTRA conservative to prevent overflow
    if (screenWidth < 350) {
      return {
        'fixedColumnWidth': 120.0,  // Reduced from 190
        'dataColumnWidth': 90.0,    // Reduced from 120
        'headerHeight': 48.0,       // Reduced from 56
        'padding': 8.0,              // Reduced from 16
        'cellPadding': 8.0,          // Reduced from 16
        'headerFontSize': 11.0,      // Reduced from 14
        'cellFontSize': 11.0,        // Reduced from 14
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'fixedColumnWidth': 140.0,
        'dataColumnWidth': 100.0,
        'headerHeight': 50.0,
        'padding': 10.0,
        'cellPadding': 10.0,
        'headerFontSize': 12.0,
        'cellFontSize': 12.0,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'fixedColumnWidth': 150.0,
        'dataColumnWidth': 110.0,
        'headerHeight': 52.0,
        'padding': 12.0,
        'cellPadding': 12.0,
        'headerFontSize': 13.0,
        'cellFontSize': 13.0,
      };
    }
    // Regular phones
    else if (screenWidth < 600) {
      return {
        'fixedColumnWidth': 170.0,
        'dataColumnWidth': 115.0,
        'headerHeight': 54.0,
        'padding': 14.0,
        'cellPadding': 14.0,
        'headerFontSize': 14.0,
        'cellFontSize': 14.0,
      };
    }
    // Tablets
    else if (screenWidth < 900) {
      return {
        'fixedColumnWidth': 180.0,
        'dataColumnWidth': 118.0,
        'headerHeight': 55.0,
        'padding': 15.0,
        'cellPadding': 15.0,
        'headerFontSize': 14.0,
        'cellFontSize': 14.0,
      };
    }
    // Large tablets/desktop
    else {
      return {
        'fixedColumnWidth': 190.0,  // Original size
        'dataColumnWidth': 120.0,   // Original size
        'headerHeight': 56.0,       // Original size
        'padding': 16.0,            // Original size
        'cellPadding': 16.0,        // Original size
        'headerFontSize': 14.0,
        'cellFontSize': 14.0,
      };
    }
  }

  Widget _buildCoreHrLink(BuildContext context, Map<String, double> sizes) {
    final theme = Theme.of(context);
    final cardBg = theme.brightness == Brightness.dark
        ? theme.cardColor
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchCoreHr(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: EdgeInsets.all(sizes['padding']!),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.paid,
                color: AppTheme.primaryColor,
                size: sizes['headerFontSize']! + 10,
              ),
              SizedBox(width: sizes['padding']!),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People XD (Core HR)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: sizes['padding']! * 0.25),
                    Text(
                      'View payslips, holiday allowance & more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: sizes['headerFontSize']! + 4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayscaleTable() {
    if (_payscaleData == null || _payscaleData!.isEmpty) {
      return const Center(child: Text('No pay scale data available'));
    }

    final sizes = _getResponsiveSizes(context);

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

    // Define enhanced colors and styles
    final cardBackgroundColor = Theme.of(context).brightness == Brightness.dark 
        ? Theme.of(context).cardColor
        : Colors.white;
        
    final oddRowOverlayColor = (Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withValues(alpha: 0.04) 
        : Colors.black.withValues(alpha: 0.02));
        
    final headerBackgroundColor = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.primaryColor.withValues(alpha: 0.2)
        : AppTheme.primaryColor.withValues(alpha: 0.1);
        
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.07);

    final headerTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.9)
          : AppTheme.primaryColor.withValues(alpha: 0.9),
      fontSize: sizes['headerFontSize']!,
    );
    
    final cellTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
      fontSize: sizes['cellFontSize']!,
    );

    return Padding(
      padding: EdgeInsets.all(sizes['padding']!),
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
          SizedBox(height: sizes['padding']! * 0.5),
          Text(
            'The following rates apply based on length of service:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: sizes['padding']! * 1.25),
          _buildCoreHrLink(context, sizes),
          SizedBox(height: sizes['padding']! * 1.25),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: HorizontalSplitTable(
                fixedColumnWidth: sizes['fixedColumnWidth']!,
                headerHeight: sizes['headerHeight']!,
                headerBackgroundColor: headerBackgroundColor,
                dataColumnWidth: sizes['dataColumnWidth']!,
                cellPadding: sizes['cellPadding']!,
                fixedColumnHeader: labelMap[fixedColumnKey] ?? fixedColumnKey,
                dataColumnHeaders: scrollableColumnHeaders.map((header) => labelMap[header] ?? header).toList(),
                rowCount: _payscaleData!.length,
                fixedColumnCellBuilder: (context, index) {
                  Map<String, dynamic> row = _payscaleData![index];
                  String cellValue = row[fixedColumnKey] ?? '';
                  cellValue = paymentTypeFormatMap[cellValue.toLowerCase()] ?? cellValue;
                  
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: sizes['cellPadding']!),
                    child: Text(
                      cellValue, 
                      style: cellTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ), 
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  );
                },
                dataCellBuilder: (context, rowIndex, colIndex) {
                  Map<String, dynamic> row = _payscaleData![rowIndex];
                  String header = scrollableColumnHeaders[colIndex];
                  String cellValue = row[header] ?? '';
                  
                  try {
                    final value = double.parse(cellValue);
                    cellValue = '€${value.toStringAsFixed(2)}';
                  } catch (e) {
                    // Keep original
                  }
                  
                  return Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: sizes['cellPadding']!),
                    child: Text(
                      cellValue, 
                      style: cellTextStyle,
                      textAlign: TextAlign.right,
                    ),
                  );
                },
                alternateRowColor: oddRowOverlayColor,
                headerTextStyle: headerTextStyle,
                borderColor: borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalSplitTable extends StatefulWidget {
  final double fixedColumnWidth;
  final double headerHeight;
  final Color headerBackgroundColor;
  final double dataColumnWidth;
  final double cellPadding;
  final String fixedColumnHeader;
  final List<String> dataColumnHeaders;
  final int rowCount;
  final Widget Function(BuildContext, int) fixedColumnCellBuilder;
  final Widget Function(BuildContext, int, int) dataCellBuilder;
  final Color alternateRowColor;
  final TextStyle headerTextStyle;
  final Color borderColor;

  const HorizontalSplitTable({
    super.key,
    required this.fixedColumnWidth,
    required this.headerHeight,
    required this.headerBackgroundColor,
    required this.dataColumnWidth,
    required this.cellPadding,
    required this.fixedColumnHeader,
    required this.dataColumnHeaders,
    required this.rowCount,
    required this.fixedColumnCellBuilder,
    required this.dataCellBuilder,
    required this.alternateRowColor,
    required this.headerTextStyle,
    required this.borderColor,
  });

  @override
  HorizontalSplitTableState createState() => HorizontalSplitTableState();
}

class HorizontalSplitTableState extends State<HorizontalSplitTable> {
  final ScrollController _horizontalScrollController1 = ScrollController();
  final ScrollController _horizontalScrollController2 = ScrollController();
  final ScrollController _verticalScrollController1 = ScrollController();
  final ScrollController _verticalScrollController2 = ScrollController();
  bool _isScrollingHorizontally = false;
  bool _isScrollingVertically = false;

  @override
  void initState() {
    super.initState();
    
    // Set up horizontal scroll synchronization
    _horizontalScrollController1.addListener(() {
      if (!_isScrollingHorizontally) {
        _isScrollingHorizontally = true;
        _horizontalScrollController2.jumpTo(_horizontalScrollController1.offset);
        _isScrollingHorizontally = false;
      }
    });
    
    _horizontalScrollController2.addListener(() {
      if (!_isScrollingHorizontally) {
        _isScrollingHorizontally = true;
        _horizontalScrollController1.jumpTo(_horizontalScrollController2.offset);
        _isScrollingHorizontally = false;
      }
    });
    
    // Set up vertical scroll synchronization
    _verticalScrollController1.addListener(() {
      if (!_isScrollingVertically) {
        _isScrollingVertically = true;
        _verticalScrollController2.jumpTo(_verticalScrollController1.offset);
        _isScrollingVertically = false;
      }
    });
    
    _verticalScrollController2.addListener(() {
      if (!_isScrollingVertically) {
        _isScrollingVertically = true;
        _verticalScrollController1.jumpTo(_verticalScrollController2.offset);
        _isScrollingVertically = false;
      }
    });
  }

  @override
  void dispose() {
    _horizontalScrollController1.dispose();
    _horizontalScrollController2.dispose();
    _verticalScrollController1.dispose();
    _verticalScrollController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = widget.dataColumnWidth * widget.dataColumnHeaders.length;
    
    return Column(
      children: [
        // Header Row
        SizedBox(
          height: widget.headerHeight,
          child: Row(
            children: [
              // Top-left fixed cell
              Container(
                width: widget.fixedColumnWidth,
                height: widget.headerHeight,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: widget.cellPadding),
                decoration: BoxDecoration(
                  color: widget.headerBackgroundColor,
                  border: Border(
                    right: BorderSide(color: widget.borderColor, width: 1),
                    bottom: BorderSide(color: widget.borderColor, width: 1),
                  ),
                ),
                child: Text(
                  widget.fixedColumnHeader,
                  style: widget.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Header scrollable part
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController1,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                    height: widget.headerHeight,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: widget.headerBackgroundColor,
                      border: Border(
                        bottom: BorderSide(color: widget.borderColor, width: 1),
                      ),
                    ),
                    child: Row(
                      children: List.generate(widget.dataColumnHeaders.length, (index) {
                        return Container(
                          width: widget.dataColumnWidth,
                          height: widget.headerHeight,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: widget.cellPadding),
                          child: Text(
                            widget.dataColumnHeaders[index],
                            style: widget.headerTextStyle,
                            textAlign: TextAlign.right,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed left column
              SizedBox(
                width: widget.fixedColumnWidth,
                child: ListView.builder(
                  controller: _verticalScrollController1,
                  itemCount: widget.rowCount,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                      height: widget.headerHeight,
                      decoration: BoxDecoration(
                        color: index.isOdd ? widget.alternateRowColor : Colors.transparent,
                        border: Border(
                          right: BorderSide(color: widget.borderColor, width: 1),
                          bottom: BorderSide(color: widget.borderColor.withValues(alpha: 0.5), width: 1),
                        ),
                      ),
                      child: widget.fixedColumnCellBuilder(context, index),
                    );
                  },
                ),
              ),
              // Scrollable data area
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController2,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth,
                    child: ListView.builder(
                      controller: _verticalScrollController2,
                      itemCount: widget.rowCount,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, rowIndex) {
                        return Container(
                          height: widget.headerHeight,
                          decoration: BoxDecoration(
                            color: rowIndex.isOdd ? widget.alternateRowColor : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(color: widget.borderColor.withValues(alpha: 0.5), width: 1),
                            ),
                          ),
                          child: Row(
                            children: List.generate(widget.dataColumnHeaders.length, (colIndex) {
                              return SizedBox(
                                width: widget.dataColumnWidth,
                                child: widget.dataCellBuilder(context, rowIndex, colIndex),
                              );
                            }),
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
    );
  }
} 
