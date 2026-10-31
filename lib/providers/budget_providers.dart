import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _storage = 'place.selection';

  var _touched = false;

  @override
  PlaceSelection build() {
    _restore();
    return const NationalPlace();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_touched) return;
    final raw = prefs.getString(_storage);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        state = PlaceSelection.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {
      return;
    }
  }

  Future<void> select(PlaceSelection place) async {
    _touched = true;
    state = place;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storage, jsonEncode(place.toJson()));
  }
}

final placeProvider = NotifierProvider<PlaceController, PlaceSelection>(
  PlaceController.new,
);

final districtsProvider = FutureProvider.family<DistrictPage, String>(
  (ref, q) async => (await ref.watch(budgetApiProvider).districts(q: q)).data,
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
