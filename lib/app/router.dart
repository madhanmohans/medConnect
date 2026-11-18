import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_providers.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/otp_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/institutions/domain/search_query.dart';
import '../features/institutions/presentation/dashboard_page.dart';
import '../features/institutions/presentation/institution_details_page.dart';
import '../features/institutions/presentation/search_results_page.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const home = '/';
  static const search = '/search';
  static String institution(String id) => '/institutions/$id';

  /// Routes reachable without signing in.
  static const public = {login, register, forgotPassword, otp};
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authControllerProvider), state.uri),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: Routes.otp,
        redirect: (_, state) =>
            state.uri.queryParameters['email'] == null ? Routes.login : null,
        builder: (_, state) =>
            OtpPage(email: state.uri.queryParameters['email']!),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, state) => ForgotPasswordPage(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterPage()),
      GoRoute(path: Routes.home, builder: (_, _) => const DashboardPage()),
      GoRoute(
        path: Routes.search,
        builder: (_, state) => SearchResultsPage(
          query: SearchQuery.fromQueryParameters(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/institutions/:id',
        builder: (_, state) =>
            InstitutionDetailsPage(institutionId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Pure redirect logic, exposed for tests.
String? authRedirect(AsyncValue<Object?> auth, Uri uri) {
  final loc = uri.path;
  if (auth.isLoading && !auth.hasValue) {
    if (loc == Routes.splash) return null;
    return Uri(
      path: Routes.splash,
      queryParameters: {'from': uri.toString()},
    ).toString();
  }
  final loggedIn = auth.value != null;
  if (loc == Routes.splash) {
    final from = uri.queryParameters['from'];
    if (!loggedIn) return Routes.login;
    return (from == null || Routes.public.contains(Uri.parse(from).path))
        ? Routes.home
        : from;
  }
  final isPublic = Routes.public.contains(loc);
  if (!loggedIn && !isPublic) return Routes.login;
  if (loggedIn && isPublic) return Routes.home;
  return null;
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
