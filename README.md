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

## Shell

- **Welcome** (`/welcome`, the opening screen) - the app logo, a welcome message, and an
  **Appearance** selector (System / Light / Dark) so the theme can be set before the app
  opens; the choice is stored on the device. "Continue to the budget" opens the national
  page, and if nobody taps it the screen opens the budget by itself after 30 seconds.
  The Android launch window is white too, so there is no colour flash before the first
  frame. The mark is the official BetterGov.ph logo,
  bundled at `assets/images/welcome_logo.png` (512 px, transparent) and shown through
  `AppLogo(asset: …)`; without `asset` the widget falls back to the blue ₱ tile. In dark
  mode it uses the white mark at `assets/images/welcome_logo_dark.png` with no plate or
  background; if `darkAsset:` is omitted the light mark is drawn on a white plate so it
  stays legible.
- **National page** (`/`) - the whole Philippines; no tab bar, one animated circle at the
  bottom. Tapping it animates the button, then opens the place sheet.
- **Hero card** - the blue summary panel (NEP vs House bill) is a credit-card surface:
  gradient, gloss, stacked back card and a perspective tilt in light mode; in dark mode it
  drops the tilt and the stacked card and uses a deeper sapphire gradient with a neutral
  shadow, because the 3D cues read as a skew on a dark canvas.
- **Map (per scope)** - the Money tab gains a **List · Map** toggle when the scope
  contains lines that publish coordinates: DPWH road lines (about 13% of them) and every
  farm-to-market road; health facilities and irrigation publish none. The preview fits
  the dots to the scope and stays non-interactive so it never fights the tab swipe;
  "Open the full map" (`/map`) is pannable and zooms. **Tapping a dot labels it**: a
  callout gives the project title, its office and program, the House amount and the status
  group, with "Open line" in the full map and a close button everywhere; a long press
  shows the title as a tooltip. Dots are coloured by status group and sized by the House
  amount, the caption states how many of the view's lines are on the map, and if the
  OpenStreetMap tiles cannot load the dots still draw with a note instead of an error.
- **Place sheet** - a search field, then All Philippines and the 18 regions grouped
  Metro Manila / Luzon / Visayas / Mindanao. Regions without published DPWH data are
  shown disabled. Typing a province, city, municipality, district or region searches
  three things at once, without leaving the sheet: **cities and municipalities** (every
  2027 line and enacted program whose name says it, with the count), **legislative
  districts**, and **regions**.
- **Region environment** (`/region/:key`) - back arrow, region title, and the two tabs
  (Money, Enacted) animate in. Districts and name search are reachable from the place
  button inside the region; `/region/all` is the shell for a district or name scope that
  is not tied to one region.
- **About** (`/about`) - opened from the ⓘ button in the app bar of the national page or
  of a place, so it is not a per-place tab. It describes the view you are in (what it
  counts, the scope's own disclaimers, whether the list is capped), then the app: version,
  API and source, what the app sends to Firebase, and the rules it keeps - the API's own
  rules printed word for word.
- **Appearance** - the theme is chosen on the welcome screen (System / Light / Dark) and
  remembered on the device. Both themes share one palette
  (`AppColors`, a `ThemeExtension`), so cards, borders, chips, inputs and the navigation
  bar all swap together; the theme change is animated over 320 ms.
- **Back** - returns to the national page and the single circle.

Routes: `/welcome`, `/`, `/region/:key`, `/region/:key/enacted`, `/place`, `/about`,
`/map`, `/project/:dataset/:id`.

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
  router/            GoRouter (national, region tabs, place, project)
  presentation/      region shell, circle button, place sheet, screens
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

## Security notes

- **Android hardening** - `android:allowBackup="false"` with `fullBackupContent="false"`
  and `res/xml/data_extraction_rules.xml` (prefs, databases and files excluded), and
  `android:usesCleartextTraffic="false"`. The only exported components are `MainActivity`
  (launcher) and AndroidX's `ProfileInstallReceiver`, which is guarded by
  `android.permission.DUMP`.
- **Release signing** - the upload keystore lives outside git
  (`android/app/upload-keystore.jks` + `android/key.properties`, both ignored). Keep a
  backup: without it you cannot publish an update.
- **Links** - every URL that comes from the API is opened through
  `openExternal()` (`core/utils/links.dart`), which only hands `http`/`https` to the
  platform, so a `javascript:`/`intent:`/`file:` URL cannot reach another app.
- **Telemetry** - Analytics and Crashlytics start disabled in debug builds; events carry
  a dataset name, a line id and a tab name, never a place, account or device identifier.
- **No other secrets** - the only credentials in the repo are Firebase *client*
  identifiers (`google-services.json`, `GoogleService-Info.plist`,
  `lib/firebase_options.dart`). Restrict them in the Google Cloud console to the Android
  package `ph.bettergov.budget` (plus the release SHA-1) and the iOS bundle id, and turn on
  App Check.
- No deep links, no WebView, no file writes; the only local storage is the theme choice.

## App icon

The launcher icons come from the official BetterGov.ph mark at
`assets/images/welcome_logo.png`: white background, art scaled to 86% of the tile, so the
mask on any launcher still clears the artwork. Android ships
`mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` at 48/72/96/144/192 px; iOS ships
all 15 `AppIcon.appiconset` slots; `assets/images/app_icon_512.png` is the 512 px master for
store listings. Regenerate them all from the source PNG (crop to the alpha bounding box,
scale to fill, flatten on white) whenever the mark changes.
