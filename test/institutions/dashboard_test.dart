import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_connect/core/mock/json_loader.dart';
import 'package:med_connect/features/institutions/data/mock_institution_repository.dart';
import 'package:med_connect/features/institutions/domain/models.dart';
import 'package:med_connect/features/institutions/domain/search_query.dart';
import 'package:med_connect/features/institutions/institution_providers.dart';
import 'package:med_connect/features/institutions/presentation/dashboard_page.dart';

import '../helpers/fixtures.dart';

const inst = Institution(
  id: 'inst-x',
  name: 'Government Medical College, Mysuru',
  university: 'Rajiv Gandhi University of Health Sciences',
  stateId: 'ka',
  city: 'Mysuru',
  instituteType: 'Government Institute',
  beds: 1450,
  feeMin: 48600,
  feeMax: 48600,
  stipendYear1: 90000,
  bondYears: 1,
  bondPenalty: 2000000,
  courseIds: ['gm'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommended() returns state + course matches', () async {
    final repo = MockInstitutionRepository(JsonLoader());
    final result = await repo.recommended(stateId: 'ka', courseId: 'gm');
    expect(result, isNotEmpty);
    expect(
      result.every((i) => i.stateId == 'ka' && i.courseIds.contains('gm')),
      isTrue,
    );
  });

  test('recommended() falls back to the whole state', () async {
    final repo = MockInstitutionRepository(JsonLoader());
    final result = await repo.recommended(
      stateId: 'ka',
      courseId: 'no-such-course',
    );
    expect(result, await repo.institutions(stateId: 'ka'));
  });

  test('SearchQuery round-trips through query parameters', () {
    const q = SearchQuery(rank: 5000, stateId: 'dl', courseId: 'gm');
    expect(q.toQueryParameters(), {
      'rank': '5000',
      'state': 'dl',
      'course': 'gm',
    });
    expect(SearchQuery.fromQueryParameters(q.toQueryParameters()), q);
    expect(SearchQuery.fromQueryParameters({'state': 'dl'}), isNull);
    expect(SearchQuery.fromQueryParameters({'rank': '0'}), isNull);
    expect(
      SearchQuery.fromQueryParameters({'rank': '10', 'state': ''}),
      const SearchQuery(rank: 10),
    );
  });

  testWidgets(
    'dashboard shows search form with rank prefilled and suggestions',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...lookupOverrides(),
            signedInAs(testUser),
            institutionsProvider.overrideWith((ref, _) async => const [inst]),
            recommendedInstitutionsProvider.overrideWith(
              (ref) async => const [inst],
            ),
          ],
          child: const MaterialApp(home: DashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hi, Asha'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '5000'), findsOneWidget);
      expect(find.text('Institutions for you'), findsOneWidget);
      expect(find.text('Karnataka · General Medicine'), findsOneWidget);
      expect(find.text('Government Medical College, Mysuru'), findsOneWidget);
      expect(find.text('₹48,600'), findsOneWidget);
    },
  );
}
