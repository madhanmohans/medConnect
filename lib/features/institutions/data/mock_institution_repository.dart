import '../../../core/mock/json_loader.dart';
import '../domain/institution_repository.dart';
import '../domain/models.dart';
import '../domain/search_query.dart';

class MockInstitutionRepository implements InstitutionRepository {
  MockInstitutionRepository(this._loader);

  final JsonLoader _loader;

  Future<List<Institution>>? _institutions;
  Future<List<AllotmentRow>>? _rows;

  Future<List<Institution>> _allInstitutions() => _institutions ??= _loader
      .loadList('institutions.json')
      .then((l) => l.map(Institution.fromJson).toList(growable: false));

  @override
  Future<List<Lookup>> states() async =>
      (await _loader.loadList('states.json')).map(Lookup.fromJson).toList();

  @override
  Future<List<Course>> courses() async =>
      (await _loader.loadList('courses.json')).map(Course.fromJson).toList();

  @override
  Future<List<Lookup>> quotas() async =>
      (await _loader.loadList('quotas.json')).map(Lookup.fromJson).toList();

  @override
  Future<List<Lookup>> categories() async =>
      (await _loader.loadList('categories.json')).map(Lookup.fromJson).toList();

  @override
  Future<List<Institution>> institutions({String? stateId}) async {
    final all = await _allInstitutions();
    return stateId == null
        ? all
        : all.where((i) => i.stateId == stateId).toList();
  }

  @override
  Future<Institution?> institutionById(String id) async {
    for (final i in await _allInstitutions()) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<List<Institution>> recommended({
    required String stateId,
    required String courseId,
  }) async {
    final inState = await institutions(stateId: stateId);
    final matching = inState.where((i) => i.courseIds.contains(courseId));
    return matching.isNotEmpty ? matching.toList() : inState;
  }

  /// All allotments joined with institution, course and state (cached).
  Future<List<AllotmentRow>> _allRows() => _rows ??= () async {
    final institutions = {for (final i in await _allInstitutions()) i.id: i};
    final courses = {for (final c in await this.courses()) c.id: c};
    final states = {for (final s in await this.states()) s.id: s.name};
    final allotments = (await _loader.loadList(
      'allotments.json',
    )).map(Allotment.fromJson);
    return [
      for (final a in allotments)
        AllotmentRow(
          allotment: a,
          institution: institutions[a.institutionId]!,
          course: courses[a.courseId]!,
          stateName: states[institutions[a.institutionId]!.stateId] ?? '',
        ),
    ];
  }();

  @override
  Future<PagedResult<AllotmentRow>> searchAllotments(
    SearchQuery q, {
    int pageSize = 20,
  }) async {
    final matches = (await _allRows()).where((r) {
      final a = r.allotment;
      return a.aiRank >= q.rank &&
          (q.stateId == null || r.institution.stateId == q.stateId) &&
          (q.institutionId == null || a.institutionId == q.institutionId) &&
          (q.courseId == null || a.courseId == q.courseId) &&
          (q.quota == null || a.quota == q.quota) &&
          (q.category == null || a.category == q.category) &&
          (q.courseType == null || r.course.courseType == q.courseType) &&
          (q.feeMax == null || a.fee <= q.feeMax!) &&
          (q.bondYearsMax == null || a.bondYears <= q.bondYearsMax!);
    }).toList();

    int byRank(AllotmentRow x, AllotmentRow y) =>
        x.allotment.aiRank.compareTo(y.allotment.aiRank);
    matches.sort(switch (q.sort) {
      SearchSort.rank => byRank,
      SearchSort.feeLow => (x, y) {
        final c = x.allotment.fee.compareTo(y.allotment.fee);
        return c != 0 ? c : byRank(x, y);
      },
      SearchSort.stipendHigh => (x, y) {
        final c = y.allotment.stipendYear1.compareTo(x.allotment.stipendYear1);
        return c != 0 ? c : byRank(x, y);
      },
    });

    final totalPages = matches.isEmpty
        ? 1
        : (matches.length + pageSize - 1) ~/ pageSize;
    final page = q.page.clamp(1, totalPages);
    final start = (page - 1) * pageSize;
    return PagedResult(
      items: matches.sublist(
        start.clamp(0, matches.length),
        (start + pageSize).clamp(0, matches.length),
      ),
      total: matches.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<AllotmentRow>> allotmentsForInstitution(
    String institutionId,
  ) async =>
      (await _allRows())
          .where((r) => r.institution.id == institutionId)
          .toList()
        ..sort((x, y) {
          final c = x.course.name.compareTo(y.course.name);
          if (c != 0) return c;
          final r = x.allotment.round.compareTo(y.allotment.round);
          return r != 0 ? r : x.allotment.aiRank.compareTo(y.allotment.aiRank);
        });
}
