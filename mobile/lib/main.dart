import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/zaina_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: ZainaApp()));
}

class ZainaApp extends ConsumerWidget {
  const ZainaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '在哪 ZAINA',
      theme: buildZainaTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
