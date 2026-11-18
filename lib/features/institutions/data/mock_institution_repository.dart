import '../../../core/mock/json_loader.dart';
import '../domain/institution_repository.dart';
import '../domain/models.dart';

class MockInstitutionRepository implements InstitutionRepository {
  MockInstitutionRepository(this._loader);

  final JsonLoader _loader;

  Future<List<Institution>>? _institutions;

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
}
