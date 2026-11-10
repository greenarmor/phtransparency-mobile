import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/budget_models.dart';
import 'budget_providers.dart';

class GaaBrowserData {
  const GaaBrowserData({required this.totals, required this.departments});

  final Map<int, int> totals;
  final List<GaaDepartment> departments;

  int totalFor(int year) => totals[year] ?? 0;

  List<GaaDepartment> sortedFor(int year) {
    final rows = [...departments]..sort(
      (a, b) => b.amountFor(year).compareTo(a.amountFor(year)),
    );
    return rows;
  }

  int lineItemsFor(int year) => departments.fold<int>(
    0,
    (sum, department) => sum + (department.years[year]?.count ?? 0),
  );
}

final gaaBrowserProvider = FutureProvider<GaaBrowserData>((ref) async {
  final national = await ref.watch(budgetApiProvider).nationalGaa();
  return GaaBrowserData(
    totals: national.totals,
    departments: national.departments,
  );
});

int normalizeGaaYear(String raw) {
  final year = int.tryParse(raw);
  return AppConfig.gaaYears.contains(year) ? year! : AppConfig.gaaYears.last;
}

final gaaSnapshotProvider = FutureProvider.family<GaaSnapshot, int>((ref, year) {
  return ref.watch(budgetApiProvider).gaaYearSnapshot(year);
});

final gaaDepartmentProvider = FutureProvider.family<GaaDepartmentDetail, String>(
  (ref, departmentId) => ref.watch(budgetApiProvider).gaaDepartment(
    departmentId,
  ),
);

class GaaChildrenArgs {
  const GaaChildrenArgs({
    required this.year,
    required this.departmentId,
    required this.level,
    this.parent,
  });

  final int year;
  final String departmentId;
  final String level;
  final String? parent;

  @override
  bool operator ==(Object other) =>
      other is GaaChildrenArgs &&
      other.year == year &&
      other.departmentId == departmentId &&
      other.level == level &&
      other.parent == parent;

  @override
  int get hashCode => Object.hash(year, departmentId, level, parent);
}

final gaaChildrenProvider = FutureProvider.family<GaaChildrenPage, GaaChildrenArgs>((
  ref,
  args,
) {
  return ref.watch(budgetApiProvider).gaaChildren(
    args.year,
    args.departmentId,
    level: args.level,
    parent: args.parent,
  );
});

final gaaRegionalProvider = FutureProvider<GaaRegional>(
  (ref) => ref.watch(budgetApiProvider).gaaRegional(),
);
