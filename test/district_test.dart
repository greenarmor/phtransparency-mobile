import 'package:bettergov_budget/data/services/scope_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only district engineering offices can map a place to a district', () {
    expect(isDistrictOfficeName('Bohol 1st DEO'), isTrue);
    expect(
      isDistrictOfficeName('Cebu City District Engineering Office'),
      isTrue,
    );
    expect(isDistrictOfficeName('Central Office'), isFalse);
    expect(isDistrictOfficeName('DPWH Regional Office VII'), isFalse);
    expect(isDistrictOfficeName('Regional Office'), isFalse);
  });

  test('a district search reports whether it matched by office', () {
    const direct = DistrictSearch(districts: [], match: DistrictMatch.name);
    const inferred = DistrictSearch(districts: [], match: DistrictMatch.office);
    const candidates = DistrictSearch(
      districts: [],
      match: DistrictMatch.province,
      province: 'Bohol',
    );

    expect(direct.match, DistrictMatch.name);
    expect(inferred.match, DistrictMatch.office);
    expect(candidates.province, 'Bohol');
  });
}
