import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/compose/compose_post_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/post_detail/post_detail_screen.dart';
import 'screens/sign_in/auth_providers.dart';
import 'screens/sign_in/sign_in_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in',
    redirect: (context, state) {
      final user = ref.read(authStateProvider).valueOrNull;
      final loc = state.matchedLocation;

      if (user == null) {
        return loc == '/sign-in' ? null : '/sign-in';
      }
      if (!user.onboardingCompleted) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (loc == '/sign-in' || loc == '/onboarding') return '/home';
      return null;
    },
    refreshListenable: ref.watch(authRouterRefreshProvider),
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/compose',
        builder: (_, _) => const ComposePostScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (_, state) =>
            PostDetailScreen(postId: state.pathParameters['id']!),
      ),
    ],
  );
});
