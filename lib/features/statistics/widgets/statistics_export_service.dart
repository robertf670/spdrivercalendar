// Conditional export: Android uses IO; Web uses Share-based implementation.
export 'statistics_export/statistics_export_service_io.dart'
    if (dart.library.html) 'statistics_export/statistics_export_service_web.dart';
