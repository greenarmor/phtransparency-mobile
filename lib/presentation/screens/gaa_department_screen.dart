import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../providers/gaa_browser_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/hero_card.dart';
import '../widgets/section_label.dart';
import '../widgets/year_bars.dart';

class GaaDepartmentScreen extends ConsumerWidget {
  const GaaDepartmentScreen({super.key, required this.year, required this.departmentId});

  final int year;
  final String departmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(gaaDepartmentProvider(departmentId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Department'),
            Text(
              'GAA 2020–2026',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
      ),
      body: AsyncView<GaaDepartmentDetail>(
        value: detail,
        loadingLabel: 'Reading the department budget…',
        onRetry: () => ref.invalidate(gaaDepartmentProvider(departmentId)),
        builder: (context, data) => _body(context, ref, data),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    GaaDepartmentDetail data,
  ) {
    final department = data.department;
    final amount = department.amountFor(year);
    final departmentAmounts = {
      for (final entry in department.years.entries)
        entry.key: entry.value.amount,
    };
    final agencies = [...data.agencies]..sort(
      (a, b) => b.amountFor(year).compareTo(a.amountFor(year)),
    );
    final expenseClasses = [...data.expenseClasses]..sort(
      (a, b) => b.amountFor(year).compareTo(a.amountFor(year)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gaaDepartmentProvider(departmentId));
        await ref.read(gaaDepartmentProvider(departmentId).future);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeroEyebrow('ENACTED IN $year'),
                      const SizedBox(height: 8),
                      Text(
                        department.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        compactPeso(amount),
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: YearBars(
                          amounts: departmentAmounts,
                          years: sortedYearKeys(departmentAmounts),
                          selected: year,
                          height: 58,
                          onDark: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push(
                      '/gaa/$year/departments/$departmentId/children'
                      '?level=agencies',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_tree_outlined,
                            size: 20,
                            color: context.colors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Drill the FY $year breakdown',
                              style: AppTheme.cardTitle(context, size: 14.5),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: context.colors.inkMute,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverToBoxAdapter(child: SectionLabel('Agencies and bureaus')),
          ),
          if (agencies.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: EmptyState(
                  title: 'No agencies listed',
                  body: 'This department is published as a single line.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: agencies.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _AgencyCard(
                  agency: agencies[index],
                  year: year,
                  departmentId: departmentId,
                ),
              ),
            ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverToBoxAdapter(
              child: SectionLabel('Expense classes'),
            ),
          ),
          if (expenseClasses.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: EmptyState(
                  title: 'No expense classes',
                  body: 'This department has no class breakdown.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: expenseClasses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _ExpenseCard(
                  expenseClass: expenseClasses[index],
                  year: year,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(
              children: [
                NoteCard(
                  title: 'Authority to spend, not spending',
                  body:
                      'The GAA sets what each department may spend. Within a '
                      'year the hierarchy runs agency → program → operating '
                      'unit → fund → expense class.',
                ),
                const SizedBox(height: 10),
                Text(
                  'Department ${department.id} · exact pesos',
                  style: AppTheme.meta(context, size: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgencyCard extends StatelessWidget {
  const _AgencyCard({
    required this.agency,
    required this.year,
    required this.departmentId,
  });

  final GaaAgency agency;
  final int year;
  final String departmentId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(
          '/gaa/$year/departments/$departmentId/children'
          '?level=fpaps&parent=${Uri.encodeComponent(agency.id)}'
          '&label=${Uri.encodeComponent(agency.description)}',
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agency.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.cardTitle(context, size: 14.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  AmountText(agency.amountFor(year), size: 14),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      'in $year',
                      style: AppTheme.meta(context, size: 11),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    plural(agency.years[year]?.count ?? 0, 'line', 'lines'),
                    style: AppTheme.meta(context, size: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expenseClass, required this.year});

  final GaaExpenseClass expenseClass;
  final int year;

  @override
  Widget build(BuildContext context) {
    final amounts = {
      for (final entry in expenseClass.years.entries)
        entry.key: entry.value.amount,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expenseClass.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cardTitle(context, size: 14.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AmountText(expenseClass.amountFor(year), size: 14),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    'in $year',
                    style: AppTheme.meta(context, size: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            YearBars(
              amounts: amounts,
              years: sortedYearKeys(amounts),
              selected: year,
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
