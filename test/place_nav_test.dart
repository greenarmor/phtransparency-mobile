import 'package:bettergov_budget/data/models/place.dart';
import 'package:bettergov_budget/presentation/place_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('national place goes to the root route', () {
    expect(placePath(const NationalPlace()), '/');
  });

  test('region place keeps its key in the route', () {
    expect(
      placePath(const RegionPlace(key: 'VII', label: 'Region VII')),
      '/region/VII',
    );
  });

  test('district place follows its region', () {
    expect(
      placePath(
        const DistrictPlace(
          id: 'leg:bohol:2nd',
          label: 'Bohol, 2nd District',
          jurisdiction: 'Bohol',
          regionKey: 'VII',
        ),
      ),
      '/region/VII',
    );
  });

  test('district without a region falls back to the all-place shell', () {
    expect(
      placePath(
        const DistrictPlace(
          id: 'leg:unknown',
          label: 'Unknown',
          jurisdiction: 'Unknown',
        ),
      ),
      '/region/$regionAllKey',
    );
  });

  test('named search opens the all-place shell', () {
    expect(
      placePath(const NamedPlace(q: 'Carmen', label: 'Carmen')),
      '/region/$regionAllKey',
    );
  });
}
