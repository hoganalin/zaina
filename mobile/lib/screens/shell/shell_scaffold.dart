import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/zaina_theme.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: _CupTabIcon(emoji: '🧋', selected: false),
            selectedIcon: _CupTabIcon(emoji: '🧋', selected: true),
            label: '動態',
          ),
          NavigationDestination(
            icon: _CupTabIcon(emoji: '☕', selected: false),
            selectedIcon: _CupTabIcon(emoji: '☕', selected: true),
            label: '夥伴',
          ),
          NavigationDestination(
            icon: _CupTabIcon(emoji: '🍵', selected: false),
            selectedIcon: _CupTabIcon(emoji: '🍵', selected: true),
            label: '通知',
          ),
          NavigationDestination(
            icon: _CupTabIcon(emoji: '🥤', selected: false),
            selectedIcon: _CupTabIcon(emoji: '🥤', selected: true),
            label: '訊息',
          ),
          NavigationDestination(
            icon: _CupTabIcon(emoji: '🍶', selected: false),
            selectedIcon: _CupTabIcon(emoji: '🍶', selected: true),
            label: '我',
          ),
        ],
      ),
      floatingActionButton: navigationShell.currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/compose'),
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }
}

class _CupTabIcon extends StatelessWidget {
  const _CupTabIcon({required this.emoji, required this.selected});
  final String emoji;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected
            ? ZainaPalette.brickRed.withValues(alpha: 0.15)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 18, height: 1),
      ),
    );
  }
}
