import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/services/scope_service.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/scope_map.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(scopeProvider);
    final place = ref.watch(placeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Map'),
            Text(
              place.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
      ),
      body: AsyncView<ScopeResult>(
        value: scope,
        loadingLabel: 'Reading the coordinates…',
        onRetry: () => ref.invalidate(scopeProvider),
        builder: (context, result) {
          final points = mappableProjects(result.projects);
          if (points.isEmpty) {
            return const EmptyState(
              title: 'No coordinates in this view',
              body:
                  'Only DPWH road lines and farm-to-market roads publish '
                  'coordinates. Health facilities and irrigation do not.',
            );
          }
          final total = result.projects.length;
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => ScopeMap(
                    points: points,
                    interactive: true,
                    height: constraints.maxHeight,
                    onPointTap: (item) {
                      logProjectOpen(
                        dataset: item.project.dataset,
                        id: item.project.id,
                      );
                      context.push(
                        '/project/${item.project.dataset}/${Uri.encodeComponent(item.project.id)}',
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plural(points.length, 'line')} with coordinates '
                      'of $total in this view · tap a dot to open it',
                      style: AppTheme.meta(context, size: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dot size follows the House amount. Coordinates are the '
                      'ones the source documents publish, not boundaries.',
                      style: AppTheme.meta(context, size: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
