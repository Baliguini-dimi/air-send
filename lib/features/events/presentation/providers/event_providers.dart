import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/event_repository.dart';
import '../../domain/event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return DriftEventRepository(ref.watch(appDatabaseProvider));
});

final eventListProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAll();
});
