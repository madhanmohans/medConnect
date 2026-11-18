import 'models.dart';

/// Read access to institutions and the lookup lists used by filters.
/// The mock implementation reads `assets/mock/*.json`; a real API client can
/// implement the same interface later.
abstract class InstitutionRepository {
  Future<List<Lookup>> states();
  Future<List<Course>> courses();
  Future<List<Lookup>> quotas();
  Future<List<Lookup>> categories();

  /// All institutions, optionally restricted to one state.
  Future<List<Institution>> institutions({String? stateId});

  Future<Institution?> institutionById(String id);
}
