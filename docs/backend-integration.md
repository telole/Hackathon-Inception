# Supabase backend integration

## Scope and prerequisites

The Flutter client uses the existing Pakaiankita Supabase backend. The schema,
migrations, RLS policies, Storage bucket, and RPC definitions are maintained by
the backend project; this client repository does not replace them. The backend
implementation was aligned with `origin/feat/core-backend-complete`.

Before running a live flow, apply the backend migrations and verify that the
configured Supabase project has:

- donor registration/authentication and profile provisioning;
- RLS policies for donor-owned donations and related rows;
- active, verified organizations and collection points;
- the private `donation-photos` bucket and its user/donation-scoped policies;
- `save_donation_contact(p_id, p_address, p_name, p_phone)`;
- `submit_donation(p_id)`.

Never add a service-role key to Flutter, `env.json`, source control, or build
defines. The public client key is safe to distribute only when backend access
is correctly restricted by RLS and Storage policies.

## Client configuration

`lib/core/config/supabase_config.dart` reads two compile-time values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (a client-safe anon or publishable key)

`main()` initializes Supabase only when both values are present and stops with
an explicit configuration error if only one is supplied. `env.json` is a
local-only convenience ignored by Git:

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<client-safe-key>"
}
```

Run the app with:

```powershell
flutter run --dart-define-from-file=env.json
```

When configuration is absent, repositories return explicit configuration
errors. Tests override them with in-memory implementations.

## Authentication

`supabaseClientProvider` supplies the initialized client. `authUserProvider`
exposes the initial user and subsequent Supabase auth state changes. The router
requires authentication for app routes when configured; unauthenticated users
are sent to `/auth`, and successful sign-in returns to the originally requested
route.

The auth screen supports email/password sign-in and account creation. The
backend must assign the donor role and create the profile as defined by its
auth/database workflow. The app does not use a privileged role to create
profiles or bypass RLS.

## Read operations

`SupabaseHomeRepository` reads:

- open `needs` with future deadlines, their `organizations`,
  `collection_points`, and `need_items`;
- the current donor's `donations` and nested `donation_items` /
  `inspections`;
- the donor's `profiles.display_name`.

`SupabaseDonationRepository` reads:

- active collection points belonging to active verified organizations;
- the current donor's donations with items, inspections, events, and point
  details.

Every donor-history query is scoped to the current authenticated user. RLS
remains the security boundary; client-side filters are not a substitute.

## Donation submission contract

The donation flow enforces the backend's required data before submission:

- one supported JPEG, PNG, or WebP photo, no larger than 1 MB;
- category, clothing type, size, and quantity from 1 to 99;
- all three condition checks: clean, intact, and not torn;
- an active collection-point ID for either pickup or drop-off;
- name, phone, and pickup address when the method is pickup.

Submission uses a client-generated UUID as a stable draft ID. The repository:

1. Inserts a donor-owned `donations` row in `draft` status or resumes that
   donor's existing draft after an insert conflict.
2. Inserts or updates its `donation_items` row.
3. Persists the three condition checks.
4. Calls `save_donation_contact` for pickup only.
5. Uploads the photo to the private bucket under the authenticated
   user/donation path and registers it in `donation_photos`.
6. Calls `submit_donation(p_id)` and fetches the resulting donation for the
   confirmation screen.

The submit RPC is expected to validate backend invariants and be idempotent for
an already-submitted draft. The client does not treat an upload or insert as a
successful donation until the RPC completes.

## Photo handling and retry behavior

`DonationPhotoPicker` wraps `image_picker` and is injectable in tests. The
repository validates file signatures, accepted MIME types, and the 1 MB limit
before upload. Photos remain in private Storage; the client does not create
public URLs.

Retrying within the same repository instance reuses a pending photo identity
and checks for an existing object/metadata row before retrying. Pending photo
metadata is held in memory, so a process restart during an incomplete upload
may require selecting the photo again. A future durable retry queue should be
added only with a deliberate local-storage/privacy design.

## RLS and data visibility

The client intentionally avoids fabricating information it cannot read:

- campaign received/progress totals are omitted when donor RLS does not expose
  allocation or shipment records;
- distance filtering is hidden when no user location or authoritative point
  distance is available;
- tracking advances only through statuses/events returned by the API;
- accepted-item impact uses readable inspection `passed_qty` values.

If these capabilities are added, expose them through a narrowly scoped,
authenticated backend view/RPC and document its RLS behavior. Do not weaken
table policies solely to make UI totals available.

## Failure handling

Repository and UI errors are surfaced with retry actions where retry is safe.
Common checks:

| Symptom | Check |
| --- | --- |
| Startup configuration error | Both compile-time values are present and correctly named. |
| Redirect/sign-in loop | Auth is enabled in the configured project and the session can be read. |
| Empty home screen | Open, unexpired needs exist and their organization/point relations are visible to donors. |
| Points request fails | Collection-point relation, active/verified filters, and RLS match the backend schema. |
| Donation fails at draft creation | User JWT, donor ownership policy, point ID, and required draft fields. |
| Contact save fails | RPC name/signature and pickup-only contact policy match deployed migrations. |
| Photo upload/registration fails | Bucket is private, file is within the limits, storage path policy permits the donor, and metadata policy is present. |
| Submission fails | Checklist, photo metadata, item row, and `submit_donation` contract are valid for the draft. |
| Share action unavailable | Platform share sheet support and `share_plus` platform configuration. |

Do not log auth tokens, keys, private addresses, phone numbers, or photo data
when diagnosing failures.
