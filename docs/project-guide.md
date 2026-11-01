# Project guide

## Product and interface

Pakaiankita helps people donate wearable clothing and directs donations toward
needs published by verified partners. The interface is Indonesian-first and
uses the existing SVG brand assets rather than redrawing the logo.

The core design system lives in `lib/core/theme/`:

- `PkTokens` provides semantic colors, spacing, radii, and shadows as a
  `ThemeExtension`.
- `AppTheme.light()` and `AppTheme.dark()` define Material 3 themes.
- Shared widgets in `lib/core/widgets/` implement buttons, cards, logo display,
  stitch dividers/progress, impact counters, shimmer placeholders, and the
  responsive phone frame.
- `StitchPainter` is the reusable dashed-seam painter. Keep new UI aligned with
  its reduced-motion behavior and the app's `MediaQuery.disableAnimations`
  handling.

Use the shared tokens and widgets when adding screens. Keep touch targets at
least 48 logical pixels, preserve text scaling, and test both light and dark
themes.

## Routing

The route table is in `lib/core/router/app_router.dart`.

| Route | Screen |
| --- | --- |
| `/onboarding` | Three-page introduction |
| `/auth` | Email/password sign-in and registration |
| `/home` | Donor home and verified needs |
| `/donate` | Donation wizard; optional `kategori` and `kebutuhan` query params |
| `/points` | Select a verified collection point |
| `/tracking` | Latest donation and status timeline |
| `/campaign/:id` | Need details |
| `/profile` | Donor profile and achievements |
| `/success` | Donation confirmation and shareable certificate |

Home, donation, tracking, and profile are branches of the stateful navigation
shell. When Supabase is configured, unauthenticated users are redirected to
`/auth`, with their requested destination retained as a redirect parameter.

## Feature ownership

- `features/home`: `HomeRepository`, home snapshot, campaign/need mapping, and
  home providers.
- `features/donation`: clothing/donation models, `DonationRepository`, service
  point loading, draft submission, photo selection, and donation status data.
- `features/auth`: Supabase email/password sign-in and account creation.
- `features/campaign`, `features/tracking`, and `features/profile`: presentation
  of backend-backed data using shared providers.

Keep network parsing and Supabase table operations in repositories. Widgets
should expose loading, error, empty, and populated states rather than inventing
successful data when a request fails.

## Data behavior and known visibility limits

- Home campaign cards represent open needs with future deadlines. Campaign
  counts and progress are not shown because donor-facing RLS does not expose
  allocation/shipment totals.
- The impact count is based on inspection `passed_qty` for curated donations;
  submitted donations are counted separately.
- Collection-point distances are omitted unless the client has a trustworthy
  distance value. The app does not request device location.
- Tracking reflects states and events returned by the backend. It does not
  claim a donation was delivered when the API has not recorded that event.
- Achievements are calculated from the donor's returned donation records and
  accepted quantities; they are not a separate rewards API.

## Testing and verification

Widget tests use in-memory repositories and a deterministic photo-picker
override, so `flutter test` does not require credentials or network access.

Before submitting changes:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web
```

For an interactive end-to-end check, configure `env.json` and run the app with
`flutter run --dart-define-from-file=env.json`. Verify authentication, home
loading, upload constraints, both donation methods, tracking events, share
behavior, and light/dark presentation against a configured Supabase project.

## Platforms

`image_picker` is used for the donation photo and `share_plus` for the
certificate. Review their platform setup when adding a target or changing
permissions. Web and desktop layouts are contained in the shared 390-by-844
phone frame; native platforms use the available screen size.
