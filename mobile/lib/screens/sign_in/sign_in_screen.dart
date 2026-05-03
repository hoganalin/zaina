import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/zaina_theme.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/sun_ray_background.dart';
import '../../widgets/zaina_logo.dart';
import 'auth_providers.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error : null;
    final showApple = !kIsWeb && Platform.isIOS;

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                SizedBox(
                  height: 220,
                  child: SunRayBackground(
                    rayCount: 24,
                    maxRadius: 220,
                    child: const ZainaLogo(size: 100),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '在海外也能感受到台灣人情味',
                  style: TextStyle(
                    color: ZainaPalette.bobaBrownDeep,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '🧋  🧋  🧋',
                  style: TextStyle(fontSize: 32, letterSpacing: 6),
                ),
                const Spacer(flex: 3),
                _ProviderButton(
                  background: const Color(0xFF1877F2),
                  foreground: Colors.white,
                  icon: Icons.facebook,
                  label: 'facebook 登入',
                  onPressed: isLoading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Facebook 登入需 Firebase Console 啟用 Facebook provider 後才能用 — 暫時請走 Google',
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 10),
                _ProviderButton(
                  background: Colors.white,
                  foreground: ZainaPalette.inkBlack,
                  border: ZainaPalette.bobaBrown,
                  icon: Icons.g_mobiledata,
                  iconSize: 28,
                  label: 'google 登入',
                  onPressed: isLoading
                      ? null
                      : () => ref.read(authStateProvider.notifier).signInWithGoogle(),
                ),
                if (showApple) ...[
                  const SizedBox(height: 10),
                  _ProviderButton(
                    background: Colors.black,
                    foreground: Colors.white,
                    icon: Icons.apple,
                    label: 'apple 登入',
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authStateProvider.notifier).signInWithApple(),
                  ),
                ],
                if (isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '登入失敗：$error',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '註冊即表示您同意我們的條款。\n我們絕不會將任何內容發佈到其他平台。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ZainaPalette.bobaBrownDeep,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconSize = 20,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final IconData icon;
  final double iconSize;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize, color: foreground),
        label: Text(label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            )),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: border == null ? BorderSide.none : BorderSide(color: border!, width: 1.4),
          ),
        ),
      ),
    );
  }
}
