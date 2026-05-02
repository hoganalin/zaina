import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/home/home_screen.dart';
import 'screens/sign_in/auth_providers.dart';
import 'screens/sign_in/sign_in_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isSignedIn = authState.valueOrNull != null;
      final goingToSignIn = state.matchedLocation == '/sign-in';

      if (!isSignedIn && !goingToSignIn) return '/sign-in';
      if (isSignedIn && goingToSignIn) return '/home';
      return null;
    },
    refreshListenable: ref.watch(authRouterRefreshProvider),
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );
});
