class AppConfig {
  AppConfig._();

  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://budget.bettergov.ph',
  );

  static const appName = 'BetterGov Budget';
  static const appVersion = '1.0.3 (6)';
  static const fiscalYear = 2027;
  static const sourceUrl = 'https://budget.bettergov.ph/hgab/2027/overview';
  static const docsUrl = 'https://budget.bettergov.ph/docs';
  static const sourceRepo = 'github.com/csiiiv/DPWH-NEP-HB-2027-ANALYSIS';
  static const changesCsvUrl =
      'https://budget-assets.bettergov.ph/hgab/2027/changes-list.csv';
  static const campaignFistUrl =
      'https://budget.bettergov.ph/campaign/fist.webp';
  static const regionalGaaUrl =
      'https://transparency.bettergov.ph/data/bir/aggregates/gaa_by_region.json';

  // Official government sources, shown in the app as Play's Misleading Claims
  // policy requires for apps that present government information.
  static const officialSources = <({String label, String publisher, String url})>[
    (
      label: 'National Expenditure Program FY 2027',
      publisher: 'Department of Budget and Management',
      url: 'https://www.dbm.gov.ph/index.php/2027/national-expenditure-program-fy-2027',
    ),
    (
      label: 'General Appropriations Act FY 2026',
      publisher: 'Department of Budget and Management',
      url: 'https://www.dbm.gov.ph/index.php/2026/general-appropriations-act-gaa-fy-2026',
    ),
    (
      label: 'House Bill No. 10858, General Appropriations Bill FY 2027',
      publisher: 'House of Representatives',
      url: 'https://www.congress.gov.ph',
    ),
  ];

  static const datasets =<String>['dpwh', 'fmr', 'hfep', 'nia'];

  static const gaaYears = <int>[2020, 2021, 2022, 2023, 2024, 2025, 2026];
}
