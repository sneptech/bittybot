import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/translation/presentation/translation_screen.dart';

/// Main navigation shell — NavigationBar with Translate (index 0) and Chat
/// (index 1) tabs.
///
/// Uses [IndexedStack] so both screens stay alive when switching tabs —
/// translation state is NOT lost when the user visits the Chat tab.
///
/// RTL-ready:
/// - All padding uses [EdgeInsetsDirectional] (not [EdgeInsets]).
/// - [NavigationBar] destination order follows the RTL mirror convention
///   automatically.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0; // 0 = Translate, 1 = Chat

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const TranslationScreen(),
          const ChatScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.translate),
            label: l10n.translate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            label: l10n.chat,
          ),
        ],
      ),
    );
  }
}
