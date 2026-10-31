# Pakaiankita

Pakaiankita is a Flutter application for donating wearable clothing to verified
community needs in Indonesia. It supports donor sign-in, clothing donation
submission, collection-point selection, donation tracking, campaign details,
impact statistics, profile achievements, and a shareable donation certificate.

The app is built with Flutter, Riverpod, GoRouter, and Supabase. Its visual
identity uses the SVG assets in `assets/logo/`, Poppins typography, a warm green
and cream palette, and reusable stitched-line components.

## Requirements

- Flutter stable and Dart `^3.13.4` (see `pubspec.yaml`)
- A Supabase project with the Pakaiankita schema, policies, storage bucket, and
  RPC functions described in [the backend guide](docs/backend-integration.md)
- A Supabase project URL and client-safe anon/publishable key

Never put a Supabase `service_role` key in this app or in a client environment
file. The client key is public; database security must be enforced by Supabase
Row Level Security (RLS) and Storage policies.

## Run locally

Create a local `env.json` in the repository root; it is ignored by Git:

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<client-safe-anon-or-publishable-key>"
}
```

Then run:

```powershell
flutter pub get
flutter run --dart-define-from-file=env.json
```

The app fails at startup if only one of the two values is supplied. Without
configuration, local UI tests can inject in-memory repositories, but live data
and authentication are unavailable.

To build the web target with backend access:

```powershell
flutter build web --dart-define-from-file=env.json
```

The key passed to a Flutter client is not a secret. Do not rely on obscuring it;
configure RLS, Storage access, and database constraints correctly.

## Main commands

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web
```

Use the `--dart-define-from-file=env.json` option for interactive runs/builds
that need live Supabase access.

## Application structure

```text
lib/
  core/
    config/       Compile-time Supabase configuration
    providers/    Supabase client and auth state
    router/       Auth-aware GoRouter and mobile navigation shell
    theme/        Design tokens and light/dark themes
    widgets/      Shared branded UI, logo, and stitch painter
  features/
    auth/         Email/password sign-in and registration
    onboarding/   Introductory three-page flow
    home/         Open needs, impact summary, and campaign cards
    donation/     Donation wizard, service points, submission, success
    campaign/     Verified need details
    tracking/     Donation status and event timeline
    profile/      Donor profile and achievement badges
test/
  widget_test.dart
docs/
  project-guide.md
  backend-integration.md
```

Feature data access is separated behind repository providers. Supabase-backed
repositories are used by the app; in-memory implementations are injected by
widget tests.

## User flow

1. A new donor views onboarding, then creates an account or signs in.
2. The home screen loads verified open needs and the donor's available impact
   statistics.
3. The donor selects clothing category/type, uploads a photo, confirms the
   condition checklist, enters quantity, and selects pickup or a service point.
4. The app creates or resumes a donation draft, writes the item/contact/photo,
   submits it through the backend RPC, and displays the returned tracking code.
5. The donor can review donation events, campaign details, profile achievements,
   and share the impact certificate.

For exact routes, backend requirements, data visibility constraints, and
troubleshooting, see [the project guide](docs/project-guide.md) and
[the Supabase integration guide](docs/backend-integration.md).
