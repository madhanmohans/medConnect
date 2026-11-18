import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_connect/core/mock/json_loader.dart';
import 'package:med_connect/core/widgets/pager.dart';
import 'package:med_connect/features/institutions/data/mock_institution_repository.dart';
import 'package:med_connect/features/institutions/domain/models.dart';
import 'package:med_connect/features/institutions/domain/search_query.dart';
import 'package:med_connect/features/institutions/institution_providers.dart';
import 'package:med_connect/features/institutions/presentation/search_results_page.dart';

import '../helpers/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repo = MockInstitutionRepository(JsonLoader());

  group('searchAllotments', () {
    test(
      'only returns seats whose closing rank is at or above the student rank',
      () async {
        final r = await repo.searchAllotments(
          const SearchQuery(rank: 20000),
          pageSize: 1000,
        );
        expect(r.total, greaterThan(0));
        expect(r.items.every((row) => row.allotment.aiRank >= 20000), isTrue);
        final ranks = r.items.map((row) => row.allotment.aiRank).toList();
        expect(ranks, [...ranks]..sort());
      },
    );

    test('optional filters combine', () async {
      const q = SearchQuery(
        rank: 1000,
        stateId: 'dl',
        courseId: 'gm',
        category: 'gen',
      );
      final r = await repo.searchAllotments(q, pageSize: 1000);
      for (final row in r.items) {
        expect(row.institution.stateId, 'dl');
        expect(row.allotment.courseId, 'gm');
        expect(row.allotment.category, 'gen');
      }
      final all = await repo.searchAllotments(
        const SearchQuery(rank: 1000),
        pageSize: 1000,
      );
      expect(r.total, lessThan(all.total));
    });

    test('institution, fee and bond filters', () async {
      final inst = (await repo.institutions()).first;
      final r = await repo.searchAllotments(
        SearchQuery(
          rank: 1,
          institutionId: inst.id,
          feeMax: 100000,
          bondYearsMax: 5,
        ),
        pageSize: 1000,
      );
      expect(
        r.items.every(
          (row) => row.institution.id == inst.id && row.allotment.fee <= 100000,
        ),
        isTrue,
      );
    });

    test('pagination splits results and clamps out-of-range pages', () async {
      final p1 = await repo.searchAllotments(const SearchQuery(rank: 1));
      expect(p1.items, hasLength(20));
      expect(p1.totalPages, (p1.total / 20).ceil());
      final last = await repo.searchAllotments(
        SearchQuery(rank: 1, page: p1.totalPages),
      );
      expect(last.items.length, p1.total - (p1.totalPages - 1) * 20);
      final beyond = await repo.searchAllotments(
        SearchQuery(rank: 1, page: p1.totalPages + 5),
      );
      expect(beyond.page, p1.totalPages);
      final p2 = await repo.searchAllotments(
        const SearchQuery(rank: 1, page: 2),
      );
      expect(p2.items.first.allotment.id, isNot(p1.items.first.allotment.id));
    });

    test('sorting by fee and stipend', () async {
      final fee = await repo.searchAllotments(
        const SearchQuery(rank: 1, sort: SearchSort.feeLow),
        pageSize: 1000,
      );
      final fees = fee.items.map((r) => r.allotment.fee).toList();
      expect(fees, [...fees]..sort());
      final stip = await repo.searchAllotments(
        const SearchQuery(rank: 1, sort: SearchSort.stipendHigh),
        pageSize: 1000,
      );
      final s = stip.items.map((r) => r.allotment.stipendYear1).toList();
      expect(s, [...s]..sort((a, b) => b.compareTo(a)));
    });

    test('impossible rank returns an empty first page', () async {
      final r = await repo.searchAllotments(const SearchQuery(rank: 99999999));
      expect(r.total, 0);
      expect(r.items, isEmpty);
      expect(r.totalPages, 1);
    });
  });

  test('SearchQuery extra filters round-trip and reset paging', () {
    const q = SearchQuery(
      rank: 10,
      quota: 'aiq',
      feeMax: 50000,
      bondYearsMax: 1,
      sort: SearchSort.feeLow,
      page: 3,
    );
    expect(SearchQuery.fromQueryParameters(q.toQueryParameters()), q);
    expect(q.extraFilterCount, 3);
    expect(q.withSort(SearchSort.rank).page, 1);
    expect(q.withFilters(category: 'gen').page, 1);
    expect(q.withFilters(category: 'gen').quota, isNull);
    expect(q.withMain(const SearchQuery(rank: 99)).quota, 'aiq');
  });

  test('Pager window', () {
    expect(Pager.window(1, 1), [1]);
    expect(Pager.window(1, 5), [1, 2, null, 5]);
    expect(Pager.window(5, 10), [1, null, 4, 5, 6, null, 10]);
    expect(Pager.window(3, 10), [1, 2, 3, 4, null, 10]);
    expect(Pager.window(10, 10), [1, null, 9, 10]);
  });

  testWidgets('results page shows the summary, rows and a pager', (
    tester,
  ) async {
    // Large asset loads use an isolate, which needs real async.
    final rows = (await tester.runAsync(
      () => repo.searchAllotments(const SearchQuery(rank: 1), pageSize: 45),
    ))!.items;
    SearchQuery? lastQuery;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...lookupOverrides(),
          signedInAs(testUser),
          institutionsProvider.overrideWith((ref, _) async => const []),
          searchResultsProvider.overrideWith((ref, q) async {
            lastQuery = q;
            final start = (q.page - 1) * 20;
            return PagedResult(
              items: rows.sublist(start, (start + 20).clamp(0, rows.length)),
              total: rows.length,
              page: q.page,
              pageSize: 20,
            );
          }),
        ],
        child: const MaterialApp(
          home: SearchResultsPage(query: SearchQuery(rank: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(lastQuery, const SearchQuery(rank: 1));
    expect(find.textContaining('1–20 of 45 records'), findsOneWidget);
    expect(find.text('Rank 1'), findsOneWidget);
    expect(find.text(rows.first.institution.name), findsWidgets);
    await tester.scrollUntilVisible(find.byType(Pager), 400);
    final pager = tester.widget<Pager>(find.byType(Pager));
    expect(pager.totalPages, 3);
    expect(pager.page, 1);
  });

  testWidgets('missing rank shows a prompt', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [signedInAs(testUser)],
        child: const MaterialApp(home: SearchResultsPage(query: null)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter your rank to search.'), findsOneWidget);
  });
}
