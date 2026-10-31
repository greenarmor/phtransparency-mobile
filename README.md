# BetterGov Budget (mobile)

A mobile view of the [BetterGov.ph budget transparency portal](https://budget.bettergov.ph)
for **every place in the Philippines**: browse all 254 legislative districts, every
region, or search any province, city or municipality by name. Each view answers what the
place gets in FY 2027 under the NEP and under the House bill, with the page each figure
is on, and what has been enacted for it since 2020.

## Coverage

- **All Philippines** - national totals for the four project programs, the six status
  groups, and all 18 DPWH regions.
- **Region** - every DPWH line under that region, compared across versions.
- **Legislative district** - the DPWH ledger of every office that serves the district.
  Shared (Tier B) offices are shown whole and never split.
- **Any place by name** - every 2027 line whose title names it, across all four
  programs, plus every enacted program whose name names it.

The app remembers the last place chosen, on the device.

## Data

No backend and no database. Everything comes from the public, read-only, CORS-open
[BetterGov.ph Budget API](https://budget.bettergov.ph/docs):

| Request | Used for |
| --- | --- |
| `/api/v1/hgab/2027` | National totals, six status groups, rules, notices, disclaimers, source commit |
| `/api/v1/hgab/2027/datasets/dpwh/regions` | The 18 regions, NEP vs House |
| `/api/v1/hgab/2027/districts?q=…` | The 254 legislative districts, searchable |
| `/api/v1/hgab/2027/districts/{id}` | A district's offices, representative, history |
| `/api/v1/hgab/2027/datasets/{program}/projects?office=…` | Every DPWH line under an office, paged 200 at a time |
| `/api/v1/hgab/2027/datasets/{program}/projects?q=…` | Every 2027 line whose title names a place |
| `/api/v1/hgab/2027/datasets/{program}/projects/{id}` | One project: amounts, pages, match and reading labels |
| `/api/v1/gaa` + `/gaa/departments` | National enacted totals and the 38 departments |
| `/api/v1/gaa/departments/{id}/programs?q=…` | Enacted programs naming a place, paged by cursor |

The API republishes an independent reading of the published NEP, House Bill 10858 and
the DBM General Appropriations Acts. Host override: `--dart-define=API_BASE=…`.

## Rules the app keeps

- Amounts are integer pesos as published. A dash means "this document has no such
  line", never zero.
- NEP and House bill are two versions of one budget: **compared, never added**.
- "In the House bill only" and "in the NEP only" are **candidates**, not confirmed
  changes.
- A shared DPWH office is shown whole; its money is never split between districts.
- Enacted amounts are appropriations (authority to spend, not spending); a year counts
  only where the amount is above zero.
- Disclaimers are printed from the API response itself.

## Known limits

- The API places DPWH money by **office**, and other lines by the place their **title**
  names. It does not yet say which city or municipality a project is in, so a district
  view is the offices' ledger, and a name search finds only lines that spell the place
  out.
- The GAA (2020–2026) has no region filter; a region view shows national totals, stated
  on the screen.
- Region totals cover DPWH infrastructure only; the other three programs are not
  published by region.

## Run

```bash
flutter pub get
flutter run                      # device or simulator
dart analyze                     # static checks
flutter test                     # unit tests
flutter build apk --debug        # Android
flutter build ios --debug --no-codesign
```

## Structure

```
lib/
  core/config/       API host, fiscal year, years
  core/firebase/     Crashlytics bootstrap, Analytics events
  core/network/      Dio client and error mapping
  core/theme/        BetterGov tokens, Material 3 theme
  core/utils/        pesos, dates, status labels
  data/models/       API shapes, place selection (national/region/district/named)
  data/services/     budget_api (paging), scope_service, gaa_service
  providers/         Riverpod providers, saved place
  router/            GoRouter (/ /place /enacted /about /project/:dataset/:id)
  presentation/      shell, widgets, screens
```

## Firebase

The app is registered in the **BetterGov builders** Firebase project
(`the builders project`):

| Platform | Firebase app | Identifier |
| --- | --- | --- |
| Android | BetterGov Budget | `ph.bettergov.budget` |
| iOS | BetterGov Budget | `ph.bettergov.budget` |

`flutterfire configure` generated `lib/firebase_options.dart`, the platform config
files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) and
wired the Gradle plugins (google-services, Crashlytics). The iOS Crashlytics symbol
upload script is in the Runner target.

- **Crashlytics**: initialised in `main.dart`; uncaught Flutter and platform errors are
  recorded as fatal.
- **Analytics**: `project_open` (dataset + line id) and `tab_open` events, in
  `lib/core/firebase/analytics.dart`.
- **App Distribution**: create a tester group in the Firebase console, then
  `firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app 1:PROJECT-NUMBER:android:APP-ID`.

Firebase failures never block the budget screens: initialisation is guarded.
