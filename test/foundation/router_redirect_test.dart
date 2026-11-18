import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_connect/app/router.dart';

void main() {
  const signedIn = AsyncData<Object?>('user');
  const signedOut = AsyncData<Object?>(null);
  const loading = AsyncLoading<Object?>();

  test('loading sends to splash and remembers the target', () {
    expect(
      authRedirect(loading, Uri.parse('/search?rank=10')),
      '/splash?from=%2Fsearch%3Frank%3D10',
    );
    expect(authRedirect(loading, Uri.parse('/splash')), isNull);
  });

  test('splash resolves to target, home or login', () {
    expect(
      authRedirect(signedIn, Uri.parse('/splash?from=%2Fsearch%3Frank%3D10')),
      '/search?rank=10',
    );
    expect(authRedirect(signedIn, Uri.parse('/splash?from=%2Flogin')), '/');
    expect(
      authRedirect(signedOut, Uri.parse('/splash?from=%2Fsearch')),
      '/login',
    );
  });

  test('guards private routes and bounces signed-in users off auth pages', () {
    expect(authRedirect(signedOut, Uri.parse('/')), '/login');
    expect(
      authRedirect(signedOut, Uri.parse('/institutions/inst-001')),
      '/login',
    );
    expect(authRedirect(signedOut, Uri.parse('/register')), isNull);
    expect(authRedirect(signedIn, Uri.parse('/login')), '/');
    expect(authRedirect(signedIn, Uri.parse('/search')), isNull);
  });
}
