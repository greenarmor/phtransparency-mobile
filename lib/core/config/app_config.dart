class AppConfig {
  AppConfig._();

  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://budget.bettergov.ph',
  );

  static const appName = 'BetterGov Budget';
  static const fiscalYear = 2027;
  static const sourceUrl = 'https://budget.bettergov.ph/hgab/2027/overview';

  static const datasets = <String>['dpwh', 'fmr', 'hfep', 'nia'];

  static const gaaYears = <int>[2020, 2021, 2022, 2023, 2024, 2025, 2026];
}
