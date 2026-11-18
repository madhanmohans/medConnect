import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mock/json_loader.dart';
import '../auth/auth_providers.dart';
import 'data/mock_institution_repository.dart';
import 'domain/institution_repository.dart';
import 'domain/models.dart';
import 'domain/search_query.dart';

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

/// State id → name, for display.
final stateNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final states = await ref.watch(statesProvider.future);
  return {for (final s in states) s.id: s.name};
});

/// Dashboard suggestions for the signed-in user's state and department.
final recommendedInstitutionsProvider = FutureProvider<List<Institution>>((
  ref,
) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const [];
  return ref
      .watch(institutionRepositoryProvider)
      .recommended(stateId: user.stateId, courseId: user.courseId);
});

/// One page of search results for a query (the query includes the page).
final searchResultsProvider =
    FutureProvider.family<PagedResult<AllotmentRow>, SearchQuery>(
      (ref, query) =>
          ref.watch(institutionRepositoryProvider).searchAllotments(query),
    );
