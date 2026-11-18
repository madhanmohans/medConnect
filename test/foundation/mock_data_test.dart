import 'package:flutter_test/flutter_test.dart';
import 'package:med_connect/core/mock/json_loader.dart';
import 'package:med_connect/features/auth/domain/app_user.dart';
import 'package:med_connect/features/institutions/data/mock_institution_repository.dart';
import 'package:med_connect/features/institutions/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = JsonLoader();
  final repo = MockInstitutionRepository(loader);

  test('every mock file parses into its model', () async {
    expect(await repo.states(), isNotEmpty);
    expect(await repo.courses(), isNotEmpty);
    expect(await repo.quotas(), isNotEmpty);
    expect(await repo.categories(), isNotEmpty);
    expect(await repo.institutions(), hasLength(greaterThan(40)));
    final allotments = (await loader.loadList(
      'allotments.json',
    )).map(Allotment.fromJson).toList();
    expect(allotments, hasLength(greaterThan(500)));
    final users = (await loader.loadList(
      'users.json',
    )).map(AppUser.fromJson).toList();
    expect(users.map((u) => u.role), containsAll(UserRole.values));
    expect((await loader.loadMap('otp.json'))['mockOtp'], '123456');
  });

  test('mock data is referentially consistent', () async {
    final stateIds = (await repo.states()).map((s) => s.id).toSet();
    final courseIds = (await repo.courses()).map((c) => c.id).toSet();
    final institutions = await repo.institutions();
    final instIds = institutions.map((i) => i.id).toSet();
    for (final i in institutions) {
      expect(stateIds, contains(i.stateId));
      expect(courseIds, containsAll(i.courseIds));
    }
    for (final a in (await loader.loadList(
      'allotments.json',
    )).map(Allotment.fromJson)) {
      expect(instIds, contains(a.institutionId));
      expect(courseIds, contains(a.courseId));
    }
  });

  test('institutions can be filtered by state and looked up by id', () async {
    final delhi = await repo.institutions(stateId: 'dl');
    expect(delhi, isNotEmpty);
    expect(delhi.every((i) => i.stateId == 'dl'), isTrue);
    expect(await repo.institutionById(delhi.first.id), delhi.first);
    expect(await repo.institutionById('nope'), isNull);
  });

  test('PagedResult computes page bounds', () {
    const r = PagedResult<int>(
      items: [1, 2, 3],
      total: 43,
      page: 3,
      pageSize: 20,
    );
    expect(r.totalPages, 3);
    expect(r.firstIndex, 41);
    expect(r.lastIndex, 43);
    const empty = PagedResult<int>(items: [], total: 0, page: 1, pageSize: 20);
    expect(empty.totalPages, 1);
    expect(empty.firstIndex, 0);
  });
}
