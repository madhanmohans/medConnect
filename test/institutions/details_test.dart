import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_connect/core/mock/json_loader.dart';
import 'package:med_connect/features/institutions/data/mock_institution_repository.dart';
import 'package:med_connect/features/institutions/institution_providers.dart';
import 'package:med_connect/features/institutions/presentation/institution_details_page.dart';

import '../helpers/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repo = MockInstitutionRepository(JsonLoader());

  test(
    'allotmentsForInstitution returns only that institution, ordered',
    () async {
      final inst = (await repo.institutions()).first;
      final rows = await repo.allotmentsForInstitution(inst.id);
      expect(rows, isNotEmpty);
      expect(rows.every((r) => r.institution.id == inst.id), isTrue);
      final names = rows.map((r) => r.course.name).toList();
      expect(names, [...names]..sort());
      expect(await repo.allotmentsForInstitution('nope'), isEmpty);
    },
  );

  testWidgets('details page shows facts, courses and closing ranks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final (inst, rows) = (await tester.runAsync(() async {
      final inst = (await repo.institutions(stateId: 'ka')).first;
      return (inst, await repo.allotmentsForInstitution(inst.id));
    }))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...lookupOverrides(),
          signedInAs(testUser),
          institutionProvider.overrideWith((ref, _) async => inst),
          institutionAllotmentsProvider.overrideWith(
            (ref, _) async => rows.take(5).toList(),
          ),
        ],
        child: MaterialApp(
          home: InstitutionDetailsPage(institutionId: inst.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(inst.name), findsOneWidget);
    expect(find.text('${inst.city}, Karnataka'), findsOneWidget);
    expect(find.text('Beds'), findsOneWidget);
    expect(find.text('Courses offered'), findsOneWidget);
    expect(find.text('Closing ranks'), findsOneWidget);
    expect(find.textContaining('your rank (5,000)'), findsOneWidget);
    expect(find.text(rows.first.course.name), findsWidgets);
  });

  testWidgets('unknown institution shows not found', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...lookupOverrides(),
          signedInAs(testUser),
          institutionProvider.overrideWith((ref, _) async => null),
        ],
        child: const MaterialApp(
          home: InstitutionDetailsPage(institutionId: 'x'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Institution not found.'), findsOneWidget);
  });
}
