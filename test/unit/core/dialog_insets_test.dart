import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/widgets/dialog_insets.dart';

void main() {
  test('phone dialog stays near 90 percent of the screen', () {
    expect(
      dialogHorizontalInsetFor(screenWidth: 320, textScale: 1),
      16,
    );
    expect(
      dialogHorizontalInsetFor(screenWidth: 400, textScale: 1),
      20,
    );
  });

  test('large text uses a wider dialog', () {
    expect(
      dialogHorizontalInsetFor(screenWidth: 400, textScale: 1.3),
      12,
    );
  });

  test('wide screens do not jump past a 40 side inset', () {
    expect(
      dialogHorizontalInsetFor(screenWidth: 800, textScale: 1),
      40,
    );
    expect(
      dialogHorizontalInsetFor(screenWidth: 360, textScale: 1),
      18,
    );
  });
}
