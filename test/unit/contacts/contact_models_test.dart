import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

void main() {
  group('ContactEntry.validate', () {
    test('requires a title', () {
      expect(
        ContactEntry.validate(title: '  ', phone: '01 703 3462'),
        'Title required',
      );
    });

    test('requires phone, email, or link', () {
      expect(
        ContactEntry.validate(title: 'Depot Manager'),
        'Add a phone, email, or link',
      );
    });

    test('accepts phone, email, or url alone', () {
      expect(
        ContactEntry.validate(title: 'Depot', phone: '01 703 3462'),
        isNull,
      );
      expect(
        ContactEntry.validate(title: 'Manager', email: 'a@b.ie'),
        isNull,
      );
      expect(
        ContactEntry.validate(title: 'HR', url: 'https://example.com'),
        isNull,
      );
    });
  });

  group('display and helpers', () {
    test('subtitle prefers note, then name and phone', () {
      expect(
        const ContactEntry(
          id: '1',
          title: 'People XD',
          note: 'Payslips',
          url: 'https://example.com',
          sectionId: '',
          sortOrder: 0,
          iconKey: 'paid',
        ).displaySubtitle,
        'Payslips',
      );
      expect(
        const ContactEntry(
          id: '2',
          title: 'Clerical Office',
          name: 'John',
          phone: '01 703 3244',
          sectionId: '',
          sortOrder: 0,
          iconKey: 'description',
        ).displaySubtitle,
        'John • 01 703 3244',
      );
      expect(
        const ContactEntry(
          id: '3',
          title: 'Depot Manager',
          name: 'Tim Fitzgibbons',
          email: 'tim@example.com',
          sectionId: '',
          sortOrder: 0,
          iconKey: 'badge',
        ).displaySubtitle,
        'Tim Fitzgibbons',
      );
    });

    test('digitsForTel strips spaces', () {
      expect(digitsForTel('01 703 3462'), '017033462');
    });

    test('normalizeContactUrl adds https when missing', () {
      expect(normalizeContactUrl('example.com'), 'https://example.com');
      expect(
        normalizeContactUrl('https://my.corehr.com/x'),
        'https://my.corehr.com/x',
      );
      expect(normalizeContactUrl('  '), isNull);
    });

    test('fromFirestore treats empty strings as missing', () {
      final entry = ContactEntry.fromFirestore('id1', {
        'title': 'CMO',
        'name': '',
        'phone': '01 703 1338',
        'email': '  ',
        'sectionId': 'section_medical',
        'sortOrder': 10,
        'iconKey': 'medical_services',
      });
      expect(entry.name, isNull);
      expect(entry.email, isNull);
      expect(entry.phone, '01 703 1338');
    });

    test('copyWith can clear a phone without restoring it', () {
      const original = ContactEntry(
        id: '1',
        title: 'Both',
        phone: '01 703 0000',
        email: 'a@b.ie',
        sectionId: '',
        sortOrder: 1,
        iconKey: 'person',
      );
      final cleared = original.copyWith(phone: null, sortOrder: 10);
      expect(cleared.phone, isNull);
      expect(cleared.email, 'a@b.ie');
      expect(cleared.sortOrder, 10);
    });
  });

  group('ContactsCatalog', () {
    test('defaults match the current contact list', () {
      final catalog = ContactsCatalog.defaults();
      final groups = catalog.grouped();
      expect(groups.first.section, isNull);
      expect(groups.first.entries.single.title, 'Phibsboro Depot');
      expect(
        groups.map((g) => g.section?.name).toList(),
        [null, 'HR & Pay', 'Depot Management', 'Controllers', 'Services', 'Medical'],
      );
      expect(
        catalog.entries.map((e) => e.title).toList(),
        [
          'Phibsboro Depot',
          'People XD (Core HR)',
          'Depot Manager',
          'Depot Administrator',
          '39s Controller',
          '23/24 Controller',
          'Cs Controller',
          'Lost Property',
          'Clerical Office',
          'CMO',
        ],
      );
    });

    test('orphaned contacts sit with ungrouped', () {
      const catalog = ContactsCatalog(
        sections: [
          ContactSection(
            id: 'known',
            name: 'Known',
            sortOrder: 10,
            iconKey: 'people',
            colorArgb: 0xFF3F51B5,
          ),
        ],
        entries: [
          ContactEntry(
            id: 'a',
            title: 'Lost section',
            phone: '1',
            sectionId: 'gone',
            sortOrder: 1,
            iconKey: 'phone',
          ),
          ContactEntry(
            id: 'b',
            title: 'In known',
            phone: '2',
            sectionId: 'known',
            sortOrder: 1,
            iconKey: 'phone',
          ),
        ],
      );
      final groups = catalog.grouped();
      expect(groups.first.entries.single.title, 'Lost section');
      expect(groups.last.entries.single.title, 'In known');
    });

    test('ungrouped cards use the primary colour', () {
      final catalog = ContactsCatalog.defaults();
      final phibsboro = catalog.entries.first;
      expect(catalog.colorFor(phibsboro, null), AppTheme.primaryColor);
    });

    test('next sort orders step by 10', () {
      final catalog = ContactsCatalog.defaults();
      expect(catalog.nextEntrySortOrder(''), 20);
      expect(catalog.nextEntrySortOrder('section_controllers'), 40);
      expect(catalog.nextSectionSortOrder(), 60);
    });
  });
}
