import 'dart:async';

import 'package:air_send/features/attendance/domain/attendance.dart';
import 'package:air_send/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:air_send/features/events/domain/event.dart';
import 'package:air_send/features/events/presentation/providers/event_providers.dart';
import 'package:air_send/features/events/presentation/screens/event_detail_screen.dart';
import 'package:air_send/core/database/app_database.dart' show ExchangeMethod;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('les actions de pointage et export sont dans le flux sans FAB', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 28);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);

    final now = DateTime(2026, 10, 5);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventListProvider.overrideWith((ref) => Stream.value([_event(now)])),
          attendanceListProvider(
            'event-1',
          ).overrideWith((ref) => Stream.value([_attendance(now)])),
        ],
        child: const MaterialApp(home: EventDetailScreen(eventId: 'event-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Pointer une présence'), findsOneWidget);
    expect(find.text('Exporter la liste'), findsOneWidget);
    expect(
      tester.getRect(find.text('Exporter la liste')).bottom,
      lessThanOrEqualTo(772),
    );
    expect(tester.takeException(), isNull);
  });
}

Event _event(DateTime now) => Event(
  id: 'event-1',
  title: 'Rencontre professionnelle',
  startDate: now,
  endDate: null,
  ownerProfileId: 'profile-1',
  createdAt: now,
  updatedAt: now,
);

Attendance _attendance(DateTime now) => Attendance(
  id: 'attendance-1',
  eventId: 'event-1',
  attendeeFullName: 'Awa Koné',
  exchangeMethod: ExchangeMethod.qr,
  checkedInAt: now,
);
