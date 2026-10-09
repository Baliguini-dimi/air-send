import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/attendance_repository.dart';
import '../../domain/attendance.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return DriftAttendanceRepository(ref.watch(appDatabaseProvider));
});

final attendanceListProvider = StreamProvider.family<List<Attendance>, String>((
  ref,
  eventId,
) {
  return ref.watch(attendanceRepositoryProvider).watchForEvent(eventId);
});
