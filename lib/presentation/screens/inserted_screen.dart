import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/firebase/analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/links.dart';
import '../../data/models/budget_models.dart';
import '../../data/services/scope_service.dart';
import '../../providers/campaign_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/project_card.dart';

class InsertedScreen extends ConsumerStatefulWidget {
  const InsertedScreen({super.key});

  @override
  ConsumerState<InsertedScreen> createState() => _InsertedScreenState();
}

class _InsertedScreenState extends ConsumerState<InsertedScreen> {
  final _search = TextEditingController();
  InsertedIndex? _index;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  InsertedIndex _indexFor(List<ProjectRow> all) {
    final index = _index;
    if (index != null && identical(index.rows, all)) return index;
    return _index = InsertedIndex(all);
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(insertedProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Inserted projects'),
            Text(
              'FY ${AppConfig.fiscalYear} · House bill only',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Download the CSV list',
            onPressed: () => openExternal(AppConfig.changesCsvUrl),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: AsyncView<List<ProjectRow>>(
        value: rows,
        loadingLabel: 'Reading inserted projects…',
        onRetry: () => ref.invalidate(insertedProjectsProvider),
        builder: (context, all) => _list(context, all),
      ),
    );
  }

  Widget _list(BuildContext context, List<ProjectRow> all) {
    final filtered = _indexFor(all).filter(_search.text);
    final count = NumberFormat.decimalPattern();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(insertedProjectsProvider);
        await ref.read(insertedProjectsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search titles, offices, regions',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _search.text.trim().isEmpty
                            ? '${count.format(all.length)} inserted projects'
                            : '${count.format(filtered.length)} of ${count.format(all.length)} inserted projects',
                        style: AppTheme.meta(context, size: 12.5),
                      ),
                    ),
                    Text(
                      'Sorted by House amount',
                      style: AppTheme.meta(context, size: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                title: 'No inserted projects match',
                body: 'Try a shorter search, or clear the box.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = filtered[index];
                  return ProjectCard(
                    item: ScopedProject(project: row),
                    onTap: () {
                      logProjectOpen(dataset: row.dataset, id: row.id);
                      context.push(
                        '/project/${row.dataset}/${Uri.encodeComponent(row.id)}',
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
