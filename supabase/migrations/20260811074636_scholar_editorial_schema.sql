-- Yaqeen scholar editorial schema
--
-- This migration deliberately contains no auth user UUIDs and no production
-- profile claims. Auth identities are provisioned after an invite is accepted.

create extension if not exists pgcrypto with schema extensions;

create type public.app_role as enum ('admin', 'scholar');

create type public.insight_status as enum (
  'draft',
  'submitted',
  'published',
  'archived'
);

create type public.translation_status as enum (
  'not_started',
  'generated',
  'reviewed'
);

create table public.user_roles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null,
  assigned_by uuid references auth.users (id) on delete set null,
  assigned_at timestamptz not null default statement_timestamp()
);

comment on table public.user_roles is
  'Server/admin-managed authorization roles. Never writable by ordinary users.';

create index user_roles_assigned_by_idx
  on public.user_roles (assigned_by)
  where assigned_by is not null;

create table public.scholar_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name_en text not null,
  display_name_ar text,
  title_en text,
  title_ar text,
  bio_en text,
  bio_ar text,
  avatar_path text,
  instagram_url text,
  youtube_url text,
  facebook_url text,
  tiktok_url text,
  website_url text,
  verified boolean not null default false,
  is_public boolean not null default false,
  verified_at timestamptz,
  verified_by uuid references auth.users (id) on delete set null,
  public_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint scholar_profiles_display_name_en_not_blank
    check (btrim(display_name_en) <> ''),
  constraint scholar_profiles_display_name_ar_not_blank
    check (display_name_ar is null or btrim(display_name_ar) <> ''),
  constraint scholar_profiles_public_requires_verification
    check (not is_public or verified),
  constraint scholar_profiles_public_timestamp_consistent
    check (is_public = (public_at is not null)),
  constraint scholar_profiles_verified_timestamp_consistent
    check (verified = (verified_at is not null)),
  constraint scholar_profiles_avatar_owned_path
    check (
      avatar_path is null
      or (
        avatar_path ~ ('^' || user_id::text || '/[A-Za-z0-9._-]+$')
        and avatar_path !~ '\.\.'
      )
    ),
  constraint scholar_profiles_instagram_https
    check (instagram_url is null or instagram_url ~* '^https://[^[:space:]]+$'),
  constraint scholar_profiles_youtube_https
    check (youtube_url is null or youtube_url ~* '^https://[^[:space:]]+$'),
  constraint scholar_profiles_facebook_https
    check (facebook_url is null or facebook_url ~* '^https://[^[:space:]]+$'),
  constraint scholar_profiles_tiktok_https
    check (tiktok_url is null or tiktok_url ~* '^https://[^[:space:]]+$'),
  constraint scholar_profiles_website_https
    check (website_url is null or website_url ~* '^https://[^[:space:]]+$')
);

comment on column public.scholar_profiles.is_public is
  'Explicit admin-controlled public visibility; verified alone is insufficient.';

create index scholar_profiles_verified_by_idx
  on public.scholar_profiles (verified_by)
  where verified_by is not null;

create index scholar_profiles_public_verified_idx
  on public.scholar_profiles (updated_at desc, user_id)
  where is_public and verified;

create table public.guidance_items (
  id uuid primary key default gen_random_uuid(),
  situation_id text not null,
  verse_key text not null,
  title_en text not null,
  title_ar text not null,
  context_en text not null,
  context_ar text not null,
  surah_name_en text not null,
  surah_name_ar text not null,
  verse_ar text not null,
  verse_en text not null,
  source_hash text not null,
  source_revision integer not null default 1,
  needs_review boolean not null default true,
  active boolean not null default true,
  source_changed_at timestamptz not null default statement_timestamp(),
  last_synced_at timestamptz not null default statement_timestamp(),
  retired_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint guidance_items_situation_id_format
    check (situation_id ~ '^[A-Za-z][A-Za-z0-9_-]{0,127}$'),
  constraint guidance_items_verse_key_format
    check (verse_key ~ '^[1-9][0-9]{0,2}:[1-9][0-9]{0,2}$'),
  constraint guidance_items_editorial_copy_not_blank
    check (
      btrim(title_en) <> ''
      and btrim(title_ar) <> ''
      and btrim(context_en) <> ''
      and btrim(context_ar) <> ''
      and btrim(surah_name_en) <> ''
      and btrim(surah_name_ar) <> ''
      and btrim(verse_ar) <> ''
      and btrim(verse_en) <> ''
    ),
  constraint guidance_items_source_hash_format
    check (source_hash ~ '^[0-9a-f]{64}$'),
  constraint guidance_items_source_revision_positive
    check (source_revision > 0),
  constraint guidance_items_active_timestamp_consistent
    check (active = (retired_at is null)),
  constraint guidance_items_identity_unique
    unique (situation_id, verse_key)
);

comment on table public.guidance_items is
  'Server-synchronised snapshot of each app situation-and-ayah review target.';

create index guidance_items_review_queue_idx
  on public.guidance_items (source_changed_at asc, situation_id, verse_key)
  where active and needs_review;

create index guidance_items_active_situation_idx
  on public.guidance_items (situation_id, verse_key)
  where active;

create table public.scholar_insights (
  id uuid primary key default gen_random_uuid(),
  guidance_item_id uuid not null
    references public.guidance_items (id) on delete restrict,
  scholar_id uuid not null
    references public.scholar_profiles (user_id) on delete restrict,
  supersedes_insight_id uuid
    references public.scholar_insights (id) on delete restrict,
  body_ar text not null default '',
  body_en text,
  reference_material jsonb not null default '[]'::jsonb,
  status public.insight_status not null default 'draft',
  translation_status public.translation_status not null default 'not_started',
  translation_provider text,
  translation_model text,
  translation_generated_at timestamptz,
  translation_reviewed_at timestamptz,
  translation_reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_source_hash text,
  submitted_at timestamptz,
  published_at timestamptz,
  published_by uuid references auth.users (id) on delete set null,
  archived_at timestamptz,
  archived_by uuid references auth.users (id) on delete set null,
  revision_number integer not null default 1,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint scholar_insights_body_ar_size
    check (octet_length(body_ar) <= 100000),
  constraint scholar_insights_body_en_size
    check (body_en is null or octet_length(body_en) <= 100000),
  constraint scholar_insights_reference_material_array
    check (jsonb_typeof(reference_material) = 'array'),
  constraint scholar_insights_reference_material_size
    check (octet_length(reference_material::text) <= 100000),
  constraint scholar_insights_reviewed_source_hash_format
    check (
      reviewed_source_hash is null
      or reviewed_source_hash ~ '^[0-9a-f]{64}$'
    ),
  constraint scholar_insights_revision_number_positive
    check (revision_number > 0),
  constraint scholar_insights_translation_review_consistent
    check (
      (
        translation_status = 'reviewed'
        and translation_reviewed_at is not null
        and translation_reviewed_by is not null
      )
      or (
        translation_status <> 'reviewed'
        and translation_reviewed_at is null
        and translation_reviewed_by is null
      )
    ),
  constraint scholar_insights_generated_translation_consistent
    check (
      translation_status = 'not_started'
      or (body_en is not null and btrim(body_en) <> '')
    ),
  constraint scholar_insights_submission_consistent
    check (
      status not in ('submitted', 'published')
      or (submitted_at is not null and reviewed_source_hash is not null)
    ),
  constraint scholar_insights_publication_consistent
    check (
      status <> 'published'
      or (
        published_at is not null
        and published_by is not null
        and translation_status = 'reviewed'
        and body_en is not null
        and btrim(body_en) <> ''
        and btrim(body_ar) <> ''
      )
    ),
  constraint scholar_insights_archive_consistent
    check ((status = 'archived') = (archived_at is not null)),
  constraint scholar_insights_not_self_superseding
    check (supersedes_insight_id is null or supersedes_insight_id <> id)
);

comment on table public.scholar_insights is
  'Versioned editorial records. A draft can coexist with the currently published row.';

create index scholar_insights_guidance_item_id_idx
  on public.scholar_insights (guidance_item_id);

create index scholar_insights_scholar_id_idx
  on public.scholar_insights (scholar_id);

create index scholar_insights_supersedes_idx
  on public.scholar_insights (supersedes_insight_id)
  where supersedes_insight_id is not null;

create index scholar_insights_translation_reviewed_by_idx
  on public.scholar_insights (translation_reviewed_by)
  where translation_reviewed_by is not null;

create index scholar_insights_published_by_idx
  on public.scholar_insights (published_by)
  where published_by is not null;

create index scholar_insights_archived_by_idx
  on public.scholar_insights (archived_by)
  where archived_by is not null;

create unique index scholar_insights_one_working_copy_idx
  on public.scholar_insights (guidance_item_id, scholar_id)
  where status in ('draft', 'submitted');

create unique index scholar_insights_one_published_copy_idx
  on public.scholar_insights (guidance_item_id, scholar_id)
  where status = 'published';

create index scholar_insights_scholar_queue_idx
  on public.scholar_insights (scholar_id, status, updated_at desc)
  where status in ('draft', 'submitted');

create index scholar_insights_public_feed_idx
  on public.scholar_insights (published_at desc, scholar_id, guidance_item_id)
  where status = 'published';

create table public.scholar_insight_revisions (
  id bigint generated always as identity primary key,
  insight_id uuid not null
    references public.scholar_insights (id) on delete restrict,
  revision_number integer not null,
  guidance_item_id uuid not null
    references public.guidance_items (id) on delete restrict,
  scholar_id uuid not null
    references public.scholar_profiles (user_id) on delete restrict,
  supersedes_insight_id uuid,
  body_ar text not null,
  body_en text,
  reference_material jsonb not null,
  status public.insight_status not null,
  translation_status public.translation_status not null,
  reviewed_source_hash text,
  submitted_at timestamptz,
  published_at timestamptz,
  archived_at timestamptz,
  changed_by uuid,
  changed_by_role public.app_role,
  changed_at timestamptz not null default statement_timestamp(),
  transaction_id bigint not null default txid_current(),
  constraint scholar_insight_revisions_identity_unique
    unique (insight_id, revision_number)
);

comment on table public.scholar_insight_revisions is
  'Append-only snapshots written by database triggers; UPDATE and DELETE always fail.';

create index scholar_insight_revisions_insight_idx
  on public.scholar_insight_revisions (insight_id, revision_number desc);

create index scholar_insight_revisions_guidance_item_idx
  on public.scholar_insight_revisions (guidance_item_id, changed_at desc);

create index scholar_insight_revisions_scholar_idx
  on public.scholar_insight_revisions (scholar_id, changed_at desc);

create index scholar_insight_revisions_supersedes_idx
  on public.scholar_insight_revisions (supersedes_insight_id)
  where supersedes_insight_id is not null;

create index scholar_insight_revisions_changed_by_idx
  on public.scholar_insight_revisions (changed_by, changed_at desc)
  where changed_by is not null;

create table public.editorial_audit_log (
  id bigint generated always as identity primary key,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  actor_id uuid,
  actor_role public.app_role,
  metadata jsonb not null default '{}'::jsonb,
  happened_at timestamptz not null default statement_timestamp(),
  transaction_id bigint not null default txid_current(),
  constraint editorial_audit_log_entity_type_not_blank
    check (btrim(entity_type) <> ''),
  constraint editorial_audit_log_action_not_blank
    check (btrim(action) <> ''),
  constraint editorial_audit_log_metadata_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.editorial_audit_log is
  'Append-only security/editorial event trail; never stores insight prose.';

create index editorial_audit_log_entity_idx
  on public.editorial_audit_log (entity_type, entity_id, happened_at desc);

create index editorial_audit_log_actor_idx
  on public.editorial_audit_log (actor_id, happened_at desc)
  where actor_id is not null;

-- RLS is enabled before policies exist so a partially applied deployment fails closed.
alter table public.user_roles enable row level security;
alter table public.scholar_profiles enable row level security;
alter table public.guidance_items enable row level security;
alter table public.scholar_insights enable row level security;
alter table public.scholar_insight_revisions enable row level security;
alter table public.editorial_audit_log enable row level security;

-- Remove Postgres' default function execution surface before functions are added.
alter default privileges in schema public revoke execute on functions from public;
