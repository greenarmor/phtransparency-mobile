import 'package:bettergov_budget/core/utils/format.dart';
import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/data/services/scope_service.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectRow row({
  required String id,
  String bridgeGroup = 'unchanged',
  int? nep,
  int? house,
  bool held = false,
}) {
  return ProjectRow(
    id: id,
    dataset: 'dpwh',
    title: 'Project $id',
    program: 'DPWH',
    pap: null,
    office: 'Bohol 1st District Engineering Office',
    region: 'Region VII',
    regionKey: 'VII',
    statusLabel: 'Same amount in both',
    bridgeGroup: bridgeGroup,
    groupLabel: 'Same amount in both',
    held: held,
    nepPhp: nep,
    hgab2Php: null,
    hgab3Php: null,
    housePhp: house,
    apiPhp: null,
    deltaPhp: (nep != null && house != null) ? house - nep : null,
    nepPage: null,
    hgab2Page: null,
    hgab3Page: null,
    pdfUrl: const {},
    flags: const [],
    url: '',
  );
}

void main() {
  group('compactPeso', () {
    test('formats billions, millions, thousands', () {
      expect(compactPeso(14151587000), '₱14.15B');
      expect(compactPeso(6793160000000), '₱6,793.16B');
      expect(compactPeso(120000000), '₱120.0M');
      expect(compactPeso(4500), '₱5K');
      expect(compactPeso(900), '₱900');
    });

    test('a dash is not zero', () {
      expect(compactPeso(null), '-');
      expect(fullPeso(null), '-');
    });

    test('signed amounts keep the direction', () {
      expect(signedCompactPeso(1500000), '+₱1.5M');
      expect(signedCompactPeso(-1500000), '−₱1.5M');
      expect(signedCompactPeso(null), '-');
    });
  });

  group('Summary', () {
    test('keeps NEP and House apart and counts groups', () {
      final summary = Summary.of([
        row(id: '1', nep: 100, house: 100),
        row(id: '2', bridgeGroup: 'house_only', house: 250),
        row(id: '3', bridgeGroup: 'nep_only', nep: 50),
        row(id: '4', bridgeGroup: 'increased', nep: 10, house: 40, held: true),
      ]);

      expect(summary.rows, 4);
      expect(summary.nepPhp, 160);
      expect(summary.housePhp, 390);
      expect(summary.nepRows, 3);
      expect(summary.houseRows, 3);
      expect(summary.groups['house_only']!.rows, 1);
      expect(summary.groups['nep_only']!.nepPhp, 50);
      expect(summary.unconfirmed, 1);
    });
  });

  test('titleCasePlace capitalises a typed place name', () {
    expect(titleCasePlace('carmen'), 'Carmen');
    expect(titleCasePlace('  cebu   city '), 'Cebu City');
    expect(titleCasePlace('sta. cruz'), 'Sta. Cruz');
  });

  test('plural groups thousands like the peso figures do', () {
    expect(plural(1, 'line'), '1 line');
    expect(plural(0, 'line'), '0 lines');
    expect(plural(796, 'project line'), '796 project lines');
    expect(plural(13460, 'line'), '13,460 lines');
    expect(plural(2, 'program funded', 'programs funded'), '2 programs funded');
  });
}
