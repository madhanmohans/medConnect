import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mock/json_loader.dart';
import 'data/mock_institution_repository.dart';
import 'domain/institution_repository.dart';
import 'domain/models.dart';

final jsonLoaderProvider = Provider<JsonLoader>((ref) => JsonLoader());

final institutionRepositoryProvider = Provider<InstitutionRepository>(
  (ref) => MockInstitutionRepository(ref.watch(jsonLoaderProvider)),
);

final statesProvider = FutureProvider<List<Lookup>>(
  (ref) => ref.watch(institutionRepositoryProvider).states(),
);

final coursesProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(institutionRepositoryProvider).courses(),
);

final quotasProvider = FutureProvider<List<Lookup>>(
  (ref) => ref.watch(institutionRepositoryProvider).quotas(),
);

final categoriesProvider = FutureProvider<List<Lookup>>(
  (ref) => ref.watch(institutionRepositoryProvider).categories(),
);

/// Institutions, optionally filtered by state id (null = all).
final institutionsProvider = FutureProvider.family<List<Institution>, String?>(
  (ref, stateId) =>
      ref.watch(institutionRepositoryProvider).institutions(stateId: stateId),
);
