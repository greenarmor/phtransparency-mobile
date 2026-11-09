import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/cache_store.dart';
import '../data/models/budget_models.dart';
import '../data/models/place.dart';
import '../data/services/budget_api.dart';
import '../data/services/scope_service.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(cacheStore: FileCacheStore()),
);

/// True while the API is unreachable and cached responses are being shown.
final servingFromCacheProvider = Provider<ValueNotifier<bool>>(
  (ref) => ref.watch(apiClientProvider).servingFromCache,
);

final budgetApiProvider = Provider<BudgetApi>(
  (ref) => BudgetApi(ref.watch(apiClientProvider)),
);

final scopeServiceProvider = Provider<ScopeService>(
  (ref) => ScopeService(ref.watch(budgetApiProvider)),
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

final districtSearchProvider = FutureProvider.family<DistrictSearch, String>(
  (ref, q) => ref.watch(scopeServiceProvider).searchDistricts(q),
);

final regionsProvider = FutureProvider<RegionsPage>(
  (ref) async => (await ref.watch(budgetApiProvider).regions()).data,
);

final scopeProvider = FutureProvider<ScopeResult>(
  (ref) => ref.watch(scopeServiceProvider).load(ref.watch(placeProvider)),
);

final overviewProvider = FutureProvider<Overview>(
  (ref) async => (await ref.watch(budgetApiProvider).overview()).data,
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
