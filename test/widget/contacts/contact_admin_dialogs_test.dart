import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';
import 'package:spdrivercalendar/features/contacts/dialogs/contact_admin_dialogs.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required Widget dialog,
    Size size = const Size(320, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => dialog,
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('contact dialog fits 320px and requires an action', (tester) async {
    ContactEntry? saved;
    await pumpDialog(
      tester,
      dialog: ContactEditDialog(
        sections: ContactsCatalog.defaults().sections,
        initialSectionId: '',
        onSave: (draft) async => saved = draft,
      ),
    );

    expect(find.text('Add contact'), findsOneWidget);
    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));

    await tester.enterText(find.byKey(const ValueKey('contact_title')), 'New person');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add a phone, email, or link'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.byKey(const ValueKey('contact_phone')), '01 703 1111');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(saved?.title, 'New person');
    expect(saved?.phone, '01 703 1111');
    expect(saved?.email, isNull);
  });

  testWidgets('contact dialog saves phone and email together', (tester) async {
    ContactEntry? saved;
    await pumpDialog(
      tester,
      dialog: ContactEditDialog(
        sections: ContactsCatalog.defaults().sections,
        initialSectionId: 'section_controllers',
        onSave: (draft) async => saved = draft,
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('contact_title')), 'Spare desk');
    await tester.enterText(find.byKey(const ValueKey('contact_name')), 'Pat');
    await tester.enterText(find.byKey(const ValueKey('contact_phone')), '01 703 0001');
    await tester.enterText(
      find.byKey(const ValueKey('contact_email')),
      'pat@dublinbus.ie',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(saved?.name, 'Pat');
    expect(saved?.phone, '01 703 0001');
    expect(saved?.email, 'pat@dublinbus.ie');
    expect(saved?.sectionId, 'section_controllers');
  });

  testWidgets('section dialog requires a name', (tester) async {
    ContactSection? saved;
    await pumpDialog(
      tester,
      dialog: ContactSectionEditDialog(
        onSave: (draft) async => saved = draft,
      ),
    );

    expect(find.text('Add section'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Section name required'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.byKey(const ValueKey('contact_section_name')), 'Union');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(saved?.name, 'Union');
  });
}
