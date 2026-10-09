import 'package:air_send/core/database/app_database.dart';
import 'package:air_send/features/attendance/data/attendance_export_service.dart';
import 'package:air_send/features/attendance/domain/attendance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('neutralise une formule CSV provenant du nom du contact', () {
    final csv = AttendanceExportService().buildCsvContent([
      Attendance(
        id: 'attendance-1',
        eventId: 'event-1',
        attendeeFullName: '=1+1',
        attendeeCompany: '+SUM(A1:A2)',
        attendeeJobTitle: '-2+3',
        attendeePhone: '@malicious',
        attendeeEmail: 'person@example.com',
        exchangeMethod: ExchangeMethod.qr,
        checkedInAt: DateTime(2026, 10, 8, 12),
      ),
    ]);

    expect(csv, contains("'=1+1"));
    expect(csv, contains("'+SUM(A1:A2)"));
    expect(csv, contains("'-2+3"));
    expect(csv, contains("'@malicious"));
  });
}
