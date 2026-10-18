import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/pz2_to_route13_migrator.dart';

void main() {
  test('rewrites PZ2 duty titles and nested codes in events JSON', () async {
    final store = <String, String>{
      AppConstants.eventsStorageKey:
          '{"d":[{"title":"PZ2/01","assignedDuties":["PZ2/04A"],'
          '"busAssignments":{"PZ2/04A":"42"}}]}',
      '${AppConstants.eventsStorageKey}${Pz2ToRoute13Migrator.backupSuffix}':
          '{"d":[{"title":"PZ2/1X"}]}',
    };

    final changed = await Pz2ToRoute13Migrator.migrate(
      readString: (key) async => store[key],
      writeString: (key, value) async {
        store[key] = value;
      },
    );

    expect(changed, isTrue);
    expect(
      store[AppConstants.eventsStorageKey],
      '{"d":[{"title":"13/01","assignedDuties":["13/04A"],'
      '"busAssignments":{"13/04A":"42"}}]}',
    );
    expect(
      store['${AppConstants.eventsStorageKey}${Pz2ToRoute13Migrator.backupSuffix}'],
      '{"d":[{"title":"13/1X"}]}',
    );
  });

  test('leaves storage alone when there are no PZ2 codes', () async {
    const original = '{"d":[{"title":"PZ1/01"}]}';
    final store = {AppConstants.eventsStorageKey: original};
    var writes = 0;

    final changed = await Pz2ToRoute13Migrator.migrate(
      readString: (key) async => store[key],
      writeString: (key, value) async {
        writes += 1;
        store[key] = value;
      },
    );

    expect(changed, isFalse);
    expect(writes, 0);
    expect(store[AppConstants.eventsStorageKey], original);
  });
}
