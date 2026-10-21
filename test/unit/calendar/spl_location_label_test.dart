import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/universal_board_timeline.dart';

void main() {
  test('a garage special leaves the terminus', () {
    expect(splLocationLabel('Mountjoy Square'), 'From Mountjoy Square');
    expect(splLocationLabel('Grange Castle'), 'From Grange Castle');
  });

  test('a garage destination stays To Garage', () {
    expect(splLocationLabel('Garage'), 'To Garage');
    expect(splLocationLabel('Phibsboro Garage'), 'To Phibsboro Garage');
  });
}
