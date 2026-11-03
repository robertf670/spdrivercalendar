import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/services/bus_tracking_service.dart';

void main() {
  const fleetHtml = '''
<tr id="none-7423">
<td class="tabular">
<a href="/vehicles/none-7423">

EW144

</a>
</td>
</tr>
<tr id="ie-5503">
<td class="tabular">
<a href="/vehicles/ie-5503">

EA15

</a>
</td>
</tr>
<tr id="ie-538">
<td><a href="/vehicles/ie-538">

VT47

</a></td>
</tr>
<tr id="ie-5384">
<td><a href="/vehicles/ie-5384">

SG99

</a></td>
</tr>
''';

  test('finds newer buses whose bustimes id is none-', () {
    expect(
      BusTrackingService.findVehicleIdInFleetHtml(fleetHtml, 'EW144'),
      'none-7423',
    );
  });

  test('still finds older ie- ids', () {
    expect(
      BusTrackingService.findVehicleIdInFleetHtml(fleetHtml, 'EA15'),
      'ie-5503',
    );
  });

  test('does not treat a shorter vehicle id as a longer one', () {
    expect(
      BusTrackingService.findVehicleIdInFleetHtml(fleetHtml, 'VT47'),
      'ie-538',
    );
    expect(
      BusTrackingService.findVehicleIdInFleetHtml(fleetHtml, 'SG99'),
      'ie-5384',
    );
  });
}
