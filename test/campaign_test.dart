import 'package:bettergov_budget/core/theme/app_theme.dart';
import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/presentation/widgets/campaign_banner.dart';
import 'package:bettergov_budget/providers/campaign_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DatasetTotals _dataset(
  String key,
  String label,
  String short, {
  int addedRows = 0,
  int addedPhp = 0,
  int droppedRows = 0,
  int droppedPhp = 0,
  int raisedRows = 0,
  int raisedPhp = 0,
  int loweredRows = 0,
  int loweredPhp = 0,
  int scopePhp = 0,
  int unconfirmed = 0,
}) => DatasetTotals(
  key: key,
  label: label,
  short: short,
  nepPhp: 1000,
  housePhp: 1200,
  nepRows: 10,
  houseRows: 12,
  groups: {
    'house_only': GroupTotal(
      rows: addedRows,
      php: addedPhp,
      unconfirmedRows: unconfirmed,
    ),
    'nep_only': GroupTotal(
      rows: droppedRows,
      php: droppedPhp,
      unconfirmedRows: 0,
    ),
    'increased': GroupTotal(rows: raisedRows, php: raisedPhp, unconfirmedRows: 0),
    'decreased': GroupTotal(
      rows: loweredRows,
      php: loweredPhp,
      unconfirmedRows: 0,
    ),
    'scope_review': GroupTotal(rows: 0, php: scopePhp, unconfirmedRows: 0),
  },
);

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: CampaignBanner(
          summary: CampaignSummary.of([
            _dataset(
              'dpwh',
              'DPWH national infrastructure',
              'DPWH',
              addedRows: 6193,
              addedPhp: 172149788000,
              droppedRows: 1341,
              droppedPhp: 75670229000,
              raisedRows: 188,
              raisedPhp: 4561952000,
              loweredRows: 194,
              loweredPhp: 87039358000,
              scopePhp: 149434000,
              unconfirmed: 389,
            ),
            _dataset(
              'fmr',
              'DA farm-to-market roads',
              'FMR',
              addedRows: 355,
              addedPhp: 5969005000,
              droppedRows: 95,
              droppedPhp: 2295905000,
              raisedRows: 1,
              raisedPhp: 15000000,
              loweredRows: 3,
              loweredPhp: 60000000,
            ),
          ]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the campaign summary adds up the four movements', () {
    final summary = CampaignSummary.of([
      _dataset(
        'dpwh',
        'DPWH national infrastructure',
        'DPWH',
        addedRows: 100,
        addedPhp: 1000,
        droppedRows: 10,
        droppedPhp: 200,
        raisedRows: 5,
        raisedPhp: 50,
        loweredRows: 2,
        loweredPhp: 20,
        scopePhp: 3,
        unconfirmed: 4,
      ),
      _dataset(
        'nia',
        'NIA irrigation',
        'NIA',
        addedRows: 30,
        addedPhp: 400,
        droppedRows: 8,
        droppedPhp: 100,
        raisedRows: 1,
        raisedPhp: 10,
        loweredRows: 1,
        loweredPhp: 5,
      ),
    ]);

    expect(summary.addedRows, 130);
    expect(summary.addedPhp, 1400);
    expect(summary.droppedRows, 18);
    expect(summary.droppedPhp, 300);
    expect(summary.raisedRows, 6);
    expect(summary.raisedPhp, 60);
    expect(summary.loweredRows, 3);
    expect(summary.loweredPhp, 25);
    expect(summary.unconfirmedRows, 4);
    // house_only − nep_only + increased − decreased + scope_review
    expect(summary.netPhp, 1400 - 300 + 60 - 25 + 3);
    expect(summary.datasets, hasLength(2));
    expect(summary.datasets.first.short, 'DPWH');
    expect(summary.datasets.first.addedRows, 100);
  });

  testWidgets('the budget banner shows the campaign message', (tester) async {
    await _pump(tester);

    expect(find.text('WE ARE'), findsOneWidget);
    expect(find.text('NOT'), findsOneWidget);
    expect(find.text('IGNORANT'), findsOneWidget);
    expect(
      find.text('6,934 inserted and adjusted projects in the 2027 House '
          'budget bill. We read every single one.'),
      findsOneWidget,
    );
    expect(find.text('FROM THE LIST'), findsNothing);
    expect(find.text('DOWNLOAD THE FULL LIST (CSV)'), findsNothing);
  });
}
