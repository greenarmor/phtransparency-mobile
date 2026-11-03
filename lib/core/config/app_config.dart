class AppConfig {
  AppConfig._();

  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://budget.bettergov.ph',
  );

  static const appName = 'BetterGov Budget';
  static const appVersion = '1.0.1 (2)';
  static const fiscalYear = 2027;
  static const sourceUrl = 'https://budget.bettergov.ph/hgab/2027/overview';
  static const docsUrl = 'https://budget.bettergov.ph/docs';
  static const sourceRepo = 'github.com/csiiiv/DPWH-NEP-HB-2027-ANALYSIS';
  static const changesCsvUrl =
      'https://budget-assets.bettergov.ph/hgab/2027/changes-list.csv';
  static const campaignFistUrl =
      'https://budget.bettergov.ph/campaign/fist.webp';

  static const datasets = <String>['dpwh', 'fmr', 'hfep', 'nia'];

  static const gaaYears = <int>[2020, 2021, 2022, 2023, 2024, 2025, 2026];
}
