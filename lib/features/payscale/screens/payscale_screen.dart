import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/core/widgets/correction_note.dart';
import 'package:spdrivercalendar/features/payscale/payscale_catalog.dart';
import 'package:spdrivercalendar/services/pay_scale_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class PayscaleScreen extends StatefulWidget {
  const PayscaleScreen({
    super.key,
    this.initialYearLevel,
    this.catalog,
  });

  final String? initialYearLevel;
  final PayScaleCatalog? catalog;

  @override
  PayscaleScreenState createState() => PayscaleScreenState();
}

class PayscaleScreenState extends State<PayscaleScreen> {
  static const String _coreHrUrl =
      'https://my.corehr.com/pls/coreportal_dbp/cp_por_public_main_page.display_login_page';

  late String _selectedYear;
  PayScaleCatalog? _catalog;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedYear = PayScaleService.normalizeYearLevel(widget.initialYearLevel);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final savedYear = widget.initialYearLevel ??
          await StorageService.getString(AppConstants.spreadPayRateKey);
      final catalog = widget.catalog ??
          PayScaleCatalog.parse(
            await rootBundle.loadString('pay/payscale.csv'),
          );
      if (!mounted) return;
      setState(() {
        _selectedYear = PayScaleService.normalizeYearLevel(savedYear);
        _catalog = catalog;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading pay scales: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchCoreHr(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(_coreHrUrl);
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

  Map<String, double> _sizes(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 350) {
      return {'padding': 8.0, 'gap': 8.0, 'fontSize': 13.0};
    }
    if (width < 400) {
      return {'padding': 10.0, 'gap': 10.0, 'fontSize': 13.5};
    }
    if (width < 450) {
      return {'padding': 12.0, 'gap': 12.0, 'fontSize': 14.0};
    }
    return {'padding': 16.0, 'gap': 12.0, 'fontSize': 14.0};
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _sizes(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Scale'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            sizes['padding']!,
            sizes['padding']!,
            sizes['padding']!,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CorrectionNote(
                pageLabel: 'the Pay Scale page',
                padding: EdgeInsets.only(bottom: 8),
              ),
              _buildCoreHrLink(context, sizes),
              SizedBox(height: sizes['gap']!),
              _yearToggle(),
              SizedBox(height: sizes['gap']!),
              Expanded(child: _buildBody(sizes)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yearToggle() {
    const rows = [
      ['year1+2', 'year3+4'],
      ['year5', 'year6'],
    ];
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outline.withValues(alpha: 0.25),
                ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      if (c > 0)
                        Container(
                          width: 1,
                          color: scheme.outline.withValues(alpha: 0.25),
                        ),
                      Expanded(child: _yearCell(rows[r][c])),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _yearCell(String yearLevel) {
    final width = MediaQuery.sizeOf(context).width;
    final selected = _selectedYear == yearLevel;
    return Material(
      key: ValueKey('payscale-year-$yearLevel'),
      color: selected ? AppTheme.primaryColor : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_selectedYear == yearLevel) return;
          setState(() => _selectedYear = yearLevel);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: width < 350 ? 10 : 12),
          child: Text(
            PayScaleService.getYearLevelDisplayName(yearLevel),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: width < 350 ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoreHrLink(BuildContext context, Map<String, double> sizes) {
    final theme = Theme.of(context);
    final cardBg = theme.brightness == Brightness.dark
        ? theme.cardColor
        : Colors.white;
    final iconSize = sizes['fontSize']! + 10;

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
                size: iconSize,
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
                size: sizes['fontSize']! + 4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Map<String, double> sizes) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    final catalog = _catalog;
    if (catalog == null || catalog.rows.isEmpty) {
      return const Center(child: Text('No pay scale data available'));
    }

    final groups = catalog.grouped();
    return ListView(
      padding: EdgeInsets.only(bottom: sizes['padding']!),
      children: [
        for (final group in groups) _sectionGroup(group, sizes),
      ],
    );
  }

  Widget _sectionGroup(PayScaleGroup group, Map<String, double> sizes) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Text(
            group.title,
            style: TextStyle(
              fontSize: width < 350 ? 12 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                for (var i = 0; i < group.rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  _rateRow(group.rows[i], sizes),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: sizes['gap']!),
      ],
    );
  }

  Widget _rateRow(PayScaleRow row, Map<String, double> sizes) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width < 350 ? 12 : 14,
        vertical: width < 350 ? 10 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: sizes['fontSize'],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            row.formattedRate(_selectedYear),
            style: TextStyle(
              fontSize: width < 350 ? 15 : 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
