import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/channels/channels_screen.dart';
import 'screens/compose/compose_post_screen.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/post_detail/post_detail_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/shell/shell_scaffold.dart';
import 'screens/sign_in/auth_providers.dart';
import 'screens/sign_in/sign_in_screen.dart';

class _MyProfileTab extends ConsumerWidget {
  const _MyProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(authStateProvider).valueOrNull?.id;
    if (id == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ProfileScreen(userId: id);
  }
}

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
      if (loc == '/sign-in' || loc == '/onboarding') return '/feed';
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
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (_, _) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/channels',
                builder: (_, _) => const ChannelsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (_, _) => const _MyProfileTab(),
              ),
            ],
          ),
        ],
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
      GoRoute(
        path: '/profile/:id',
        builder: (_, state) =>
            ProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, _) => const EditProfileScreen(),
      ),
    ],
  );
});
