import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:med_connect/features/auth/auth_providers.dart';
import 'package:med_connect/features/auth/domain/app_user.dart';
import 'package:med_connect/features/institutions/domain/models.dart';
import 'package:med_connect/features/institutions/institution_providers.dart';

const testStates = [
  Lookup(id: 'dl', name: 'Delhi'),
  Lookup(id: 'ka', name: 'Karnataka'),
];
const testCourses = [
  Course(
    id: 'gm',
    name: 'General Medicine',
    courseType: 'Clinical',
    degree: 'MD',
  ),
  Course(
    id: 'rd',
    name: 'Radio Diagnosis',
    courseType: 'Clinical',
    degree: 'MD',
  ),
];

/// Overrides lookup providers so widget tests don't touch the asset bundle.
List<Override> lookupOverrides() => [
  statesProvider.overrideWith((ref) async => testStates),
  coursesProvider.overrideWith((ref) async => testCourses),
  quotasProvider.overrideWith(
    (ref) async => const [Lookup(id: 'aiq', name: 'All India Quota')],
  ),
  categoriesProvider.overrideWith(
    (ref) async => const [Lookup(id: 'gen', name: 'GEN')],
  ),
];

const testUser = AppUser(
  id: 'u-test',
  name: 'Asha Student',
  email: 'asha@example.com',
  role: UserRole.student,
  stateId: 'ka',
  courseId: 'gm',
  aiRank: 5000,
);

class FakeAuthController extends AuthController {
  FakeAuthController(this.user);
  final AppUser? user;

  @override
  Future<AppUser?> build() async => user;
}

Override signedInAs(AppUser user) =>
    authControllerProvider.overrideWith(() => FakeAuthController(user));
