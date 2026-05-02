import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sign_in/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('在哪 ZAINA')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.waving_hand, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                user == null ? '...' : '哈囉，${user.nickname}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (user != null && !user.onboardingCompleted)
                const Text(
                  '尚未完成 Onboarding（Sprint 2 會接上）',
                  style: TextStyle(color: Colors.black54),
                ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authStateProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('登出'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
