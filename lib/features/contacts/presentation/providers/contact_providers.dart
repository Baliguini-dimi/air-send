import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/contact_repository.dart';
import '../../domain/contact.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return DriftContactRepository(ref.watch(appDatabaseProvider));
});

final contactListProvider = StreamProvider<List<Contact>>((ref) {
  return ref.watch(contactRepositoryProvider).watchAll();
});
