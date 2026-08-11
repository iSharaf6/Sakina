# Yaqeen scholar editorial backend

This directory is a deployable Supabase scaffold for invite-only scholar review.
It contains no user UUID, password, API key, service-role key, or unverified
qualification claim.

## Security and publication model

- `user_roles` is separate from profiles. Clients can never insert or update it,
  so a user cannot promote themselves.
- A profile is public only when an admin sets both `verified` and `is_public`.
- Scholars can update only non-privileged profile columns. Any scholar self-edit
  automatically makes the profile private/unverified until an admin re-reviews it;
  changed biographical claims never inherit an earlier verified badge.
- Scholars can read and edit their own draft/submitted work. Editing a submitted
  row automatically returns it to draft. Direct insight table writes remain revoked;
  every mutation uses a revision-checked RPC so custom clients cannot bypass CAS.
- Machine translation is saved only as `generated`. A scholar or admin must call
  `review_scholar_insight_translation`, then submit it.
- `publish_scholar_insight` is admin-only and rejects blank Arabic, blank English,
  non-reviewed English, private/unverified profiles, inactive guidance items, and
  a `reviewed_source_hash` that no longer matches the app.
- A working copy and published copy can coexist. Publishing a replacement archives
  the previous public row atomically; sync never deletes or unpublishes insight rows.
- Insight revisions and the editorial audit log are append-only, including against
  service-role writes through normal SQL.
- The `scholar-avatars` bucket is intentionally public so native image loaders can
  use a normal Storage public URL. It must contain public profile media only.
  Scholar uploads are insert-only, restricted to a new unique path under
  `<auth-user-uuid>/...`, and capped at 2 MB JPEG, PNG, or WebP files. Replacing
  `avatar_path` is administrator-only; the dashboard must load the exact public
  object before enabling verification. Changing the path through the admin upsert
  also makes the profile private/unverified until that explicit review. Existing objects can be overwritten or
  deleted only by an admin, preventing a verified portrait from being swapped in
  place. UUID folder names make unpublished paths
  hard to guess but are not an access-control boundary; do not upload private media.

The client-facing publishable/anon key is safe only with RLS enabled. Never ship a
service-role key, `GUIDANCE_SYNC_TOKEN`, or translation-provider key in an app or
dashboard bundle.

## Deploy

1. Create a Supabase project and disable public sign-up. Invite the admin and
   scholar accounts through Supabase Auth.
2. Apply migrations with `supabase db push`.
3. Bootstrap the first admin and private scholar profile using
   `templates/provision-dr-abdullah-abu-hatab.sql`, passing both Auth UUIDs as
   runtime `psql` variables. Do not edit UUIDs into the repository.
4. Add the supplied Arabic display name, real qualification/title, approved bios,
   and avatar. The included Dr. Abdullah Abu Hatab profile template deliberately
   leaves those unsupplied fields `null` and remains private/unverified.
5. Upload the approved image to
   `<scholar-auth-uuid>/profile.jpg` in `scholar-avatars`, update `avatar_path`,
   verify the copy with the scholar, then call:

   ```sql
   select public.admin_set_scholar_profile_visibility(
     '<scholar-auth-uuid>'::uuid,
     true,
     true
   );
   ```

   The public image URL is
   `<SUPABASE_URL>/storage/v1/object/public/scholar-avatars/<avatar_path>`.

6. Generate two independent high-entropy values and configure server secrets:

   ```sh
   supabase secrets set GUIDANCE_SYNC_TOKEN='<at-least-32-random-characters>'
   supabase secrets set OPENAI_API_KEY='<server-only-key>'
   supabase secrets set OPENAI_TRANSLATION_MODEL='<reviewed-translation-model>'
   supabase secrets set SCHOLAR_DASHBOARD_ORIGINS='https://scholars.example.org'
   ```

   `SCHOLAR_DASHBOARD_ORIGINS` is a comma-separated exact-origin allowlist. Include
   each approved dashboard origin (scheme, host, and non-default port when used).
   Browser translation requests fail closed when their origin is not listed.

7. Deploy both functions. `config.toml` intentionally disables gateway JWT
   verification only for manifest sync because that server-to-server endpoint
   performs constant-time verification of `GUIDANCE_SYNC_TOKEN`. Translation keeps
   JWT verification enabled and also verifies the caller through Supabase Auth/RLS.
8. Add `GUIDANCE_SYNC_FUNCTION_URL` and the matching `GUIDANCE_SYNC_TOKEN` as
   GitHub Actions secrets. The workflow does not need the service-role key.

## Content sync

Run locally:

```sh
node scripts/generate-guidance-manifest.mjs
node scripts/generate-guidance-manifest.mjs --check
node scripts/scholar-backend/validate.mjs
```

The generator reads the live Swift situation catalog, Arabic titles/reflections,
and bundled `verses.json`. Each deterministic SHA-256 hash covers the situation,
ayah identity, both titles, both contextual notes, Arabic ayah, and approved English
wording. A new or changed hash requeues the item. Items removed from the app become
inactive rather than being deleted.

On `main`, `.github/workflows/sync-scholar-guidance.yml` runs the iOS content tests,
checks that the committed manifest is current, performs backend static validation,
starts an isolated Supabase database, and runs both pgTAP suites before sending the
manifest to the protected Edge Function. Pull requests run the same validation but
never mutate production.

## Translation flow

`translate-scholar-insight` accepts only an authenticated `insight_id`. It reads an
editable draft through caller RLS and sends only the scholar prose plus relevant
editorial/ayah context to the translation provider. The response is stored through
the service-only `save_generated_scholar_translation` RPC. That RPC never changes
`status`, so generated text cannot auto-publish.

Dashboard draft writes should use `create_scholar_insight_draft`; replacements of a
live publication use `create_scholar_replacement_draft(p_published_insight_id)`.
Both refuse to overwrite concurrent work. Subsequent writes call
`save_scholar_insight_draft(p_insight_id, p_body_ar, p_body_en,
p_reference_material, p_expected_revision_number)`, and submission and human
translation review carry the same expected-revision contract. Stale tabs receive a
serialization conflict and must reload instead of overwriting newer editorial work.
The save RPC accepts only the author or an admin and keeps the state-reset rules in
the database rather than trusting browser code.

The public `published_scholar_content` view exposes situation titles as
`situation_title_en` and `situation_title_ar`, avoiding collisions with the
scholar's own `title_en` / `title_ar` profile fields.

Use `public_scholar_profiles` to load a verified/public profile independently of
whether it has published insights yet. It exposes only public copy, socials,
`avatar_path`, `verified`, and `updated_at`; admin verification metadata is omitted.

## Tests

- `scripts/scholar-backend/validate.mjs` is dependency-free and runs in CI.
- `supabase/tests/scholar_editorial.sql` is the pgTAP schema/policy suite.
- `supabase/tests/scholar_authorization.sql` executes the public API under anon,
  role-less authenticated, scholar, revoked-scholar, and admin JWT claims. It covers
  unpublished reads, self-role escalation, immediate role revocation, admin-only
  publish/archive, inactive-source denial, atomic replacement creation, malformed
  references, and stale revision rejection across save/translation/review/submit.
- Run both against a local or staging Supabase stack with `supabase test db`. A
  production deployment is not approved until these behavioral tests pass against
  the same migrations that will be deployed; service-role checks alone bypass RLS.
