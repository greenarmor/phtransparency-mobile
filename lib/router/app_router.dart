import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/about_screen.dart';
import '../presentation/screens/enacted_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/place_picker_screen.dart';
import '../presentation/screens/project_screen.dart';
import '../presentation/shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/enacted',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EnactedScreen()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AboutScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/place',
        builder: (context, state) => const PlacePickerScreen(),
      ),
      GoRoute(
        path: '/project/:dataset/:id',
        builder: (context, state) => ProjectScreen(
          dataset: state.pathParameters['dataset'] ?? '',
          id: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This page does not exist.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('See every project'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
