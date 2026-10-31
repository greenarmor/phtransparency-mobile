import 'dart:convert';

import 'package:bettergov_budget/data/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('national selection survives a storage round trip', () {
    const place = NationalPlace();
    final restored = PlaceSelection.fromJson(
      jsonDecode(jsonEncode(place.toJson())) as Map<String, dynamic>,
    );
    expect(restored, isA<NationalPlace>());
    expect(restored.title, 'All Philippines');
  });

  test('region selection keeps its key and label', () {
    const place = RegionPlace(
      key: 'VII',
      label: 'Region VII',
      name: 'Central Visayas',
    );
    final restored = PlaceSelection.fromJson(
      jsonDecode(jsonEncode(place.toJson())) as Map<String, dynamic>,
    );
    expect(restored, isA<RegionPlace>());
    expect((restored as RegionPlace).key, 'VII');
    expect(restored.title, 'Region VII');
  });

  test('district selection keeps the jurisdiction', () {
    const place = DistrictPlace(
      id: 'leg:bohol:1st',
      label: 'Bohol, 1st District',
      jurisdiction: 'Bohol',
      regionKey: 'VII',
    );
    final restored = PlaceSelection.fromJson(
      jsonDecode(jsonEncode(place.toJson())) as Map<String, dynamic>,
    );
    expect(restored, isA<DistrictPlace>());
    expect((restored as DistrictPlace).jurisdiction, 'Bohol');
  });

  test('named place keeps the query', () {
    const place = NamedPlace(q: 'Carmen Bohol', label: 'Carmen');
    final restored = PlaceSelection.fromJson(
      jsonDecode(jsonEncode(place.toJson())) as Map<String, dynamic>,
    );
    expect(restored, isA<NamedPlace>());
    expect((restored as NamedPlace).q, 'Carmen Bohol');
  });
}
