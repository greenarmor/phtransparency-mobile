import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../data/models/budget_models.dart';
import '../data/models/place.dart';
import '../data/services/budget_api.dart';
import '../data/services/gaa_service.dart';
import '../data/services/scope_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final budgetApiProvider = Provider<BudgetApi>(
  (ref) => BudgetApi(ref.watch(apiClientProvider)),
);

final scopeServiceProvider = Provider<ScopeService>(
  (ref) => ScopeService(ref.watch(budgetApiProvider)),
);

final gaaServiceProvider = Provider<GaaService>(
  (ref) => GaaService(ref.watch(budgetApiProvider)),
);

class PlaceController extends Notifier<PlaceSelection> {
  @override
  PlaceSelection build() => const NationalPlace();

  void select(PlaceSelection place) => state = place;
}

final placeProvider = NotifierProvider<PlaceController, PlaceSelection>(
  PlaceController.new,
);

final districtsProvider = FutureProvider.family<DistrictPage, String>(
  (ref, q) async => (await ref.watch(budgetApiProvider).districts(q: q)).data,
);

class NameMatches {
  const NameMatches({required this.byDataset, required this.lines});

  final Map<String, int> byDataset;
  final int lines;

  int get programs => byDataset.values.where((count) => count > 0).length;
}

final nameMatchesProvider = FutureProvider.family<NameMatches, String>((
  ref,
  q,
) async {
  final api = ref.watch(budgetApiProvider);
  final counts = await Future.wait(
    AppConfig.datasets.map((dataset) => api.projectMatchCount(dataset, q)),
  );
  final byDataset = <String, int>{
    for (var i = 0; i < AppConfig.datasets.length; i++)
      AppConfig.datasets[i]: counts[i],
  };
  return NameMatches(
    byDataset: byDataset,
    lines: byDataset.values.fold(0, (sum, count) => sum + count),
  );
});

final regionsProvider = FutureProvider<RegionsPage>(
  (ref) async => (await ref.watch(budgetApiProvider).regions()).data,
);

final scopeProvider = FutureProvider<ScopeResult>(
  (ref) => ref.watch(scopeServiceProvider).load(ref.watch(placeProvider)),
);

final overviewProvider = FutureProvider<Overview>(
  (ref) async => (await ref.watch(budgetApiProvider).overview()).data,
);

final gaaProvider = FutureProvider<GaaDataset>(
  (ref) => ref.watch(gaaServiceProvider).load(ref.watch(placeProvider)),
);

class ProjectArgs {
  const ProjectArgs(this.dataset, this.id);

  final String dataset;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is ProjectArgs && other.dataset == dataset && other.id == id;

  @override
  int get hashCode => Object.hash(dataset, id);
}

final projectDetailProvider = FutureProvider.family<ProjectDetail, ProjectArgs>(
  (ref, args) async =>
      (await ref.watch(budgetApiProvider).project(args.dataset, args.id)).data,
);
