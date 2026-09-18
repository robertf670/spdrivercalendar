import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';
import 'package:spdrivercalendar/features/contacts/contacts_page.dart';

void main() {
  testWidgets('renders default contacts at 320px without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ContactsPage(catalogOverride: ContactsCatalog.defaults()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Important Contacts'), findsOneWidget);
    expect(find.text('Phibsboro Depot'), findsOneWidget);
    expect(find.text('01 703 3462'), findsOneWidget);
    expect(find.text('Depot Manager'), findsOneWidget);
    expect(find.text('Tim Fitzgibbons'), findsOneWidget);
    expect(find.text('People XD (Core HR)'), findsOneWidget);
    expect(find.textContaining('send me a message'), findsOneWidget);
    expect(
      find.textContaining('If you notice anything here to be incorrect'),
      findsOneWidget,
    );
    expect(find.text('Admin Dashboard'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows call and email actions when both are set', (tester) async {
    const catalog = ContactsCatalog(
      entries: [
        ContactEntry(
          id: 'both',
          title: 'Both',
          name: 'Alex',
          phone: '01 703 0000',
          email: 'alex@example.com',
          sectionId: '',
          sortOrder: 1,
          iconKey: 'person',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ContactsPage(catalogOverride: catalog),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alex • 01 703 0000'), findsOneWidget);
    expect(find.byTooltip('Call'), findsOneWidget);
    expect(find.byTooltip('Email'), findsOneWidget);
  });
}
