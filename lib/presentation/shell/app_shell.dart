import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/analytics.dart';

import '../../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/enacted')) return 1;
    if (location.startsWith('/about')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.ruleSoft)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                logTabOpen('money');
                context.go('/');
              case 1:
                logTabOpen('enacted');
                context.go('/enacted');
              default:
                logTabOpen('about');
                context.go('/about');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Money',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Enacted',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }
}
