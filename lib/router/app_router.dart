import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/about_screen.dart';
import '../presentation/screens/enacted_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/national_screen.dart';
import '../presentation/screens/place_picker_screen.dart';
import '../presentation/screens/project_screen.dart';
import '../presentation/screens/region_screen.dart';
import '../presentation/screens/welcome_screen.dart';
import '../presentation/shell/region_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/enacted') return '/';
      if (path.endsWith('/about') && path != '/about') return '/about';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const NationalScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/place',
        builder: (context, state) => const PlacePickerScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => RegionShell(
          regionKey: state.pathParameters['key'] ?? '',
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/region/:key',
            builder: (context, state) => const RegionMoneyScreen(),
            routes: [
              GoRoute(
                path: 'enacted',
                builder: (context, state) => const EnactedScreen(),
              ),
            ],
          ),
        ],
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
                child: const Text('Back to the Philippines'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
