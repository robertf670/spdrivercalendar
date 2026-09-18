import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/payscale/payscale_catalog.dart';
import 'package:spdrivercalendar/services/pay_scale_service.dart';

const _csv = '''
type,year1+2,year3+4,year5,year6,
basicdaily,140.26,145.19,152.56,162.40
shiftdaily,23.38,24.19,25.43,27.07
weeklyexlsunday,818.19,846.90,889.97,943.34
spreadover(hourly),17.98,18.61,19.56,20.82
''';

void main() {
  test('parses rates and labels from the payscale CSV', () {
    final catalog = PayScaleCatalog.parse(_csv);
    expect(catalog.rows, hasLength(4));
    final basic = catalog.rows.first;
    expect(basic.label, 'Basic Daily Rate');
    expect(basic.section, 'Daily');
    expect(basic.formattedRate('year1+2'), '€140.26');
    expect(basic.formattedRate('year5'), '€152.56');
    expect(catalog.rows.last.section, 'Spread');
    expect(
      catalog.grouped().map((g) => g.title).toList(),
      ['Daily', 'Weekly', 'Spread'],
    );
  });

  test('normalises saved year levels', () {
    expect(PayScaleService.normalizeYearLevel('year5'), 'year5');
    expect(PayScaleService.normalizeYearLevel(null), 'year1+2');
    expect(PayScaleService.normalizeYearLevel('nope'), 'year1+2');
    expect(PayScaleService.getYearLevelDisplayName('year1+2'), 'Year 1-2');
    expect(PayScaleService.getYearLevelDisplayName('year6'), 'Year 6+');
  });

  test('loads and saves pay rate year from the Settings key', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.spreadPayRateKey: 'year6',
      'selected_year_level': 'year1+2',
    });
    await StorageService.init();
    StorageService.clearCache();

    expect(await PayScaleService.loadSavedYearLevel(), 'year6');

    await PayScaleService.saveYearLevel('year5');
    expect(await PayScaleService.loadSavedYearLevel(), 'year5');
    expect(
      await StorageService.getString(AppConstants.spreadPayRateKey),
      'year5',
    );
    expect(await StorageService.getString('selected_year_level'), 'year1+2');
  });
}
