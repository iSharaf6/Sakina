-- Authorization helpers, immutable history, editorial RPCs, RLS, and Storage.

create or replace function public.editorial_actor_id()
returns uuid
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_auth_id uuid;
  v_delegated_id text;
begin
  v_auth_id := auth.uid();
  if v_auth_id is not null then
    return v_auth_id;
  end if;

  v_delegated_id := current_setting('app.editorial_actor_id', true);
  if v_delegated_id is not null
     and v_delegated_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    return v_delegated_id::uuid;
  end if;

  return null;
end;
$$;

create or replace function public.has_app_role(p_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles ur
    where ur.user_id = (select public.editorial_actor_id())
      and ur.role = p_role
  );
$$;

create or replace function public.editorial_actor_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select ur.role
  from public.user_roles ur
  where ur.user_id = (select public.editorial_actor_id());
$$;

create or replace function public.storage_object_owner_id(p_name text)
returns uuid
language sql
immutable
security invoker
set search_path = ''
as $$
  select case
    when split_part(p_name, '/', 1)
      ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    then split_part(p_name, '/', 1)::uuid
    else null
  end;
$$;

-- Public insight references are rendered as links by both native and web clients.
-- Enforce their complete shape in Postgres so direct table writes cannot bypass
-- the dashboard's form validation or poison an entire public API response.
create or replace function public.is_valid_scholar_reference_material(p_value jsonb)
returns boolean
language sql
immutable
parallel safe
set search_path = ''
as $$
  select case
    when p_value is null or jsonb_typeof(p_value) <> 'array' then false
    when jsonb_array_length(p_value) > 50 then false
    when octet_length(p_value::text) > 100000 then false
    else not exists (
      select 1
      from jsonb_array_elements(p_value) as reference(entry)
      where jsonb_typeof(entry) <> 'object'
        or (
          (entry ? 'label' and jsonb_typeof(entry -> 'label') <> 'string')
          or (entry ? 'title' and jsonb_typeof(entry -> 'title') <> 'string')
          or not coalesce((
            (
              jsonb_typeof(entry -> 'label') = 'string'
              and char_length(btrim(entry ->> 'label')) between 1 and 500
            )
            or (
              jsonb_typeof(entry -> 'title') = 'string'
              and char_length(btrim(entry ->> 'title')) between 1 and 500
            )
          ), false)
          or (
            entry ? 'id'
            and (
              jsonb_typeof(entry -> 'id') <> 'string'
              or char_length(btrim(entry ->> 'id')) not between 1 and 200
            )
          )
          or (
            entry ? 'detail'
            and (
              jsonb_typeof(entry -> 'detail') <> 'string'
              or char_length(entry ->> 'detail') > 2000
            )
          )
          or (
            entry ? 'url'
            and (
              jsonb_typeof(entry -> 'url') <> 'string'
              or char_length(entry ->> 'url') > 2048
              or (entry ->> 'url') !~* '^https://[^[:space:]]+$'
            )
          )
        )
    )
  end;
$$;

alter table public.scholar_insights
  add constraint scholar_insights_reference_material_shape
  check (public.is_valid_scholar_reference_material(reference_material));

create or replace function public.reject_immutable_history_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception '% is append-only', tg_table_name
    using errcode = '55000';
end;
$$;

create trigger scholar_insight_revisions_immutable
before update or delete on public.scholar_insight_revisions
for each row execute function public.reject_immutable_history_change();

create trigger editorial_audit_log_immutable
before update or delete on public.editorial_audit_log
for each row execute function public.reject_immutable_history_change();

create or replace function public.prepare_scholar_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_is_admin boolean := (select public.has_app_role('admin'::public.app_role));
begin
  if (
    new.verified is distinct from old.verified
    or new.is_public is distinct from old.is_public
    or new.verified_at is distinct from old.verified_at
    or new.verified_by is distinct from old.verified_by
    or new.public_at is distinct from old.public_at
  ) and not v_is_admin then
    raise exception 'Only an admin can change verification or public visibility'
      using errcode = '42501';
  end if;

  -- Self-service copy changes must be re-verified before becoming public again.
  if not v_is_admin and (
    new.display_name_en is distinct from old.display_name_en
    or new.display_name_ar is distinct from old.display_name_ar
    or new.title_en is distinct from old.title_en
    or new.title_ar is distinct from old.title_ar
    or new.bio_en is distinct from old.bio_en
    or new.bio_ar is distinct from old.bio_ar
    or new.avatar_path is distinct from old.avatar_path
    or new.instagram_url is distinct from old.instagram_url
    or new.youtube_url is distinct from old.youtube_url
    or new.facebook_url is distinct from old.facebook_url
    or new.tiktok_url is distinct from old.tiktok_url
    or new.website_url is distinct from old.website_url
  ) then
    new.verified := false;
    new.is_public := false;
    new.verified_at := null;
    new.verified_by := null;
    new.public_at := null;
  end if;

  new.updated_at := statement_timestamp();
  return new;
end;
$$;

create trigger scholar_profiles_prepare_update
before update on public.scholar_profiles
for each row execute function public.prepare_scholar_profile_update();

create or replace function public.prepare_scholar_insight_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select public.editorial_actor_id());
  v_is_admin boolean := (select public.has_app_role('admin'::public.app_role));
  v_body_ar_changed boolean := false;
  v_body_en_changed boolean := false;
  v_references_changed boolean := false;
  v_material_change boolean := false;
  v_current_source_hash text;
  v_current_active boolean;
begin
  if tg_op = 'INSERT' then
    if new.status <> 'draft'::public.insight_status then
      raise exception 'New insights must begin as drafts' using errcode = '23514';
    end if;

    if not v_is_admin and (
      v_actor is null
      or new.scholar_id <> v_actor
      or not (select public.has_app_role('scholar'::public.app_role))
    ) then
      raise exception 'A scholar can create only their own draft'
        using errcode = '42501';
    end if;

    if new.supersedes_insight_id is null then
      select si.id
      into new.supersedes_insight_id
      from public.scholar_insights si
      where si.guidance_item_id = new.guidance_item_id
        and si.scholar_id = new.scholar_id
        and si.status = 'published'::public.insight_status
      order by si.published_at desc
      limit 1;
    end if;

    new.revision_number := 1;
    new.created_at := statement_timestamp();
    new.updated_at := statement_timestamp();
    return new;
  end if;

  v_body_ar_changed := new.body_ar is distinct from old.body_ar;
  v_body_en_changed := new.body_en is distinct from old.body_en;
  v_references_changed := new.reference_material is distinct from old.reference_material;

  if old.status in ('published'::public.insight_status, 'archived'::public.insight_status)
     and (v_body_ar_changed or v_body_en_changed or v_references_changed) then
    raise exception 'Published and archived revisions are immutable; create a new draft'
      using errcode = '55000';
  end if;

  if v_body_ar_changed then
    new.translation_status := 'not_started'::public.translation_status;
    new.translation_provider := null;
    new.translation_model := null;
    new.translation_generated_at := null;
    new.translation_reviewed_at := null;
    new.translation_reviewed_by := null;
  elsif v_body_en_changed and new.translation_status = old.translation_status then
    new.translation_status := case
      when new.body_en is null or btrim(new.body_en) = ''
        then 'not_started'::public.translation_status
      else 'generated'::public.translation_status
    end;
    new.translation_reviewed_at := null;
    new.translation_reviewed_by := null;
  end if;

  -- Editing a submitted item returns it to a draft and invalidates its source review.
  if old.status = 'submitted'::public.insight_status
     and (v_body_ar_changed or v_body_en_changed or v_references_changed) then
    new.status := 'draft'::public.insight_status;
    new.submitted_at := null;
    new.reviewed_source_hash := null;
  end if;

  if new.status is distinct from old.status then
    if old.status = 'submitted'::public.insight_status
       and new.status = 'draft'::public.insight_status
       and (v_body_ar_changed or v_body_en_changed or v_references_changed) then
      if not v_is_admin and old.scholar_id <> v_actor then
        raise exception 'Only the author or an admin can revise this submission'
          using errcode = '42501';
      end if;

    elsif old.status = 'draft'::public.insight_status
       and new.status = 'submitted'::public.insight_status then
      if not v_is_admin and old.scholar_id <> v_actor then
        raise exception 'Only the author or an admin can submit this insight'
          using errcode = '42501';
      end if;

      if btrim(new.body_ar) = ''
         or new.body_en is null
         or btrim(new.body_en) = ''
         or new.translation_status <> 'reviewed'::public.translation_status then
        raise exception 'Arabic and reviewed English are required before submission'
          using errcode = '23514';
      end if;

      new.submitted_at := coalesce(new.submitted_at, statement_timestamp());

    elsif old.status = 'submitted'::public.insight_status
       and new.status = 'published'::public.insight_status then
      if not v_is_admin then
        raise exception 'Only an admin can publish insights' using errcode = '42501';
      end if;

      select gi.source_hash, gi.active
      into v_current_source_hash, v_current_active
      from public.guidance_items gi
      where gi.id = new.guidance_item_id;

      if not coalesce(v_current_active, false)
         or new.reviewed_source_hash is distinct from v_current_source_hash then
        raise exception 'The app source changed after review; resubmit against the current source'
          using errcode = '40001';
      end if;

      if new.translation_status <> 'reviewed'::public.translation_status
         or new.body_en is null
         or btrim(new.body_en) = ''
         or btrim(new.body_ar) = '' then
        raise exception 'Reviewed Arabic and English are required before publication'
          using errcode = '23514';
      end if;

      if not exists (
        select 1
        from public.scholar_profiles sp
        where sp.user_id = new.scholar_id
          and sp.verified
          and sp.is_public
      ) then
        raise exception 'The scholar profile must be verified and public before publication'
          using errcode = '23514';
      end if;

      new.published_at := coalesce(new.published_at, statement_timestamp());
      new.published_by := coalesce(new.published_by, v_actor);

    elsif new.status = 'archived'::public.insight_status
       and old.status in (
         'draft'::public.insight_status,
         'submitted'::public.insight_status,
         'published'::public.insight_status
       ) then
      if not v_is_admin then
        raise exception 'Only an admin can archive insights' using errcode = '42501';
      end if;
      new.archived_at := coalesce(new.archived_at, statement_timestamp());
      new.archived_by := coalesce(new.archived_by, v_actor);

    else
      raise exception 'Unsupported insight status transition: % to %', old.status, new.status
        using errcode = '23514';
    end if;
  end if;

  v_material_change :=
    v_body_ar_changed
    or v_body_en_changed
    or v_references_changed
    or new.status is distinct from old.status
    or new.translation_status is distinct from old.translation_status
    or new.reviewed_source_hash is distinct from old.reviewed_source_hash
    or new.supersedes_insight_id is distinct from old.supersedes_insight_id
    or new.translation_provider is distinct from old.translation_provider
    or new.translation_model is distinct from old.translation_model;

  new.revision_number := old.revision_number + case when v_material_change then 1 else 0 end;
  new.updated_at := case when v_material_change then statement_timestamp() else old.updated_at end;
  return new;
end;
$$;

create trigger scholar_insights_prepare_write
before insert or update on public.scholar_insights
for each row execute function public.prepare_scholar_insight_write();

create or replace function public.capture_scholar_insight_revision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.revision_number = old.revision_number then
    return new;
  end if;

  insert into public.scholar_insight_revisions (
    insight_id,
    revision_number,
    guidance_item_id,
    scholar_id,
    supersedes_insight_id,
    body_ar,
    body_en,
    reference_material,
    status,
    translation_status,
    reviewed_source_hash,
    submitted_at,
    published_at,
    archived_at,
    changed_by,
    changed_by_role
  ) values (
    new.id,
    new.revision_number,
    new.guidance_item_id,
    new.scholar_id,
    new.supersedes_insight_id,
    new.body_ar,
    new.body_en,
    new.reference_material,
    new.status,
    new.translation_status,
    new.reviewed_source_hash,
    new.submitted_at,
    new.published_at,
    new.archived_at,
    (select public.editorial_actor_id()),
    (select public.editorial_actor_role())
  );

  return new;
end;
$$;

create trigger scholar_insights_capture_revision
after insert or update on public.scholar_insights
for each row execute function public.capture_scholar_insight_revision();

create or replace function public.capture_editorial_audit_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old jsonb := case when tg_op = 'INSERT' then '{}'::jsonb else to_jsonb(old) end;
  v_new jsonb := case when tg_op = 'DELETE' then '{}'::jsonb else to_jsonb(new) end;
  v_row jsonb := case when tg_op = 'DELETE' then v_old else v_new end;
  v_entity_id uuid;
  v_metadata jsonb;
begin
  v_entity_id := nullif(
    coalesce(v_row ->> 'id', v_row ->> 'user_id'),
    ''
  )::uuid;

  v_metadata := case tg_table_name
    when 'user_roles' then jsonb_build_object(
      'old_role', v_old ->> 'role',
      'new_role', v_new ->> 'role'
    )
    when 'scholar_profiles' then jsonb_build_object(
      'verified', v_new -> 'verified',
      'is_public', v_new -> 'is_public'
    )
    when 'guidance_items' then jsonb_build_object(
      'situation_id', v_row ->> 'situation_id',
      'verse_key', v_row ->> 'verse_key',
      'old_source_hash', v_old ->> 'source_hash',
      'new_source_hash', v_new ->> 'source_hash',
      'needs_review', v_new -> 'needs_review',
      'active', v_new -> 'active'
    )
    when 'scholar_insights' then jsonb_build_object(
      'guidance_item_id', v_row ->> 'guidance_item_id',
      'scholar_id', v_row ->> 'scholar_id',
      'old_status', v_old ->> 'status',
      'new_status', v_new ->> 'status',
      'translation_status', v_new ->> 'translation_status',
      'revision_number', v_new -> 'revision_number'
    )
    else '{}'::jsonb
  end;

  insert into public.editorial_audit_log (
    entity_type,
    entity_id,
    action,
    actor_id,
    actor_role,
    metadata
  ) values (
    tg_table_name,
    v_entity_id,
    lower(tg_op),
    (select public.editorial_actor_id()),
    (select public.editorial_actor_role()),
    jsonb_strip_nulls(v_metadata)
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger user_roles_audit
after insert or update or delete on public.user_roles
for each row execute function public.capture_editorial_audit_event();

create trigger scholar_profiles_audit
after insert or update or delete on public.scholar_profiles
for each row execute function public.capture_editorial_audit_event();

create trigger guidance_items_audit
after insert or update or delete on public.guidance_items
for each row execute function public.capture_editorial_audit_event();

create trigger scholar_insights_audit
after insert or update or delete on public.scholar_insights
for each row execute function public.capture_editorial_audit_event();

create or replace function public.admin_assign_user_role(
  p_user_id uuid,
  p_role public.app_role
)
returns public.user_roles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result public.user_roles;
begin
  if not (select public.has_app_role('admin'::public.app_role)) then
    raise exception 'Admin role required' using errcode = '42501';
  end if;

  if not exists (select 1 from auth.users u where u.id = p_user_id) then
    raise exception 'Auth user does not exist' using errcode = '23503';
  end if;

  if p_user_id = (select public.editorial_actor_id())
     and p_role <> 'admin'::public.app_role
     and (select count(*) from public.user_roles where role = 'admin'::public.app_role) = 1 then
    raise exception 'The last admin cannot demote themselves' using errcode = '23514';
  end if;

  insert into public.user_roles (user_id, role, assigned_by, assigned_at)
  values (p_user_id, p_role, (select public.editorial_actor_id()), statement_timestamp())
  on conflict (user_id) do update
    set role = excluded.role,
        assigned_by = excluded.assigned_by,
        assigned_at = excluded.assigned_at
  returning * into v_result;

  return v_result;
end;
$$;

create or replace function public.admin_upsert_scholar_profile(
  p_user_id uuid,
  p_display_name_en text,
  p_display_name_ar text default null,
  p_title_en text default null,
  p_title_ar text default null,
  p_bio_en text default null,
  p_bio_ar text default null,
  p_avatar_path text default null,
  p_instagram_url text default null,
  p_youtube_url text default null,
  p_facebook_url text default null,
  p_tiktok_url text default null,
  p_website_url text default null
)
returns public.scholar_profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result public.scholar_profiles;
begin
  if not (select public.has_app_role('admin'::public.app_role)) then
    raise exception 'Admin role required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.user_roles ur
    where ur.user_id = p_user_id and ur.role = 'scholar'::public.app_role
  ) then
    raise exception 'Assign the scholar role before creating the profile'
      using errcode = '23514';
  end if;

  insert into public.scholar_profiles (
    user_id, display_name_en, display_name_ar, title_en, title_ar,
    bio_en, bio_ar, avatar_path, instagram_url, youtube_url,
    facebook_url, tiktok_url, website_url
  ) values (
    p_user_id, btrim(p_display_name_en), nullif(btrim(p_display_name_ar), ''),
    nullif(btrim(p_title_en), ''), nullif(btrim(p_title_ar), ''),
    nullif(btrim(p_bio_en), ''), nullif(btrim(p_bio_ar), ''),
    nullif(btrim(p_avatar_path), ''), nullif(btrim(p_instagram_url), ''),
    nullif(btrim(p_youtube_url), ''), nullif(btrim(p_facebook_url), ''),
    nullif(btrim(p_tiktok_url), ''), nullif(btrim(p_website_url), '')
  )
  on conflict (user_id) do update set
    display_name_en = excluded.display_name_en,
    display_name_ar = excluded.display_name_ar,
    title_en = excluded.title_en,
    title_ar = excluded.title_ar,
    bio_en = excluded.bio_en,
    bio_ar = excluded.bio_ar,
    avatar_path = excluded.avatar_path,
    instagram_url = excluded.instagram_url,
    youtube_url = excluded.youtube_url,
    facebook_url = excluded.facebook_url,
    tiktok_url = excluded.tiktok_url,
    website_url = excluded.website_url,
    verified = case
      when scholar_profiles.avatar_path is distinct from excluded.avatar_path then false
      else scholar_profiles.verified
    end,
    is_public = case
      when scholar_profiles.avatar_path is distinct from excluded.avatar_path then false
      else scholar_profiles.is_public
    end,
    verified_at = case
      when scholar_profiles.avatar_path is distinct from excluded.avatar_path then null
      else scholar_profiles.verified_at
    end,
    verified_by = case
      when scholar_profiles.avatar_path is distinct from excluded.avatar_path then null
      else scholar_profiles.verified_by
    end,
    public_at = case
      when scholar_profiles.avatar_path is distinct from excluded.avatar_path then null
      else scholar_profiles.public_at
    end
  returning * into v_result;

  return v_result;
end;
$$;

create or replace function public.admin_set_scholar_profile_visibility(
  p_user_id uuid,
  p_verified boolean,
  p_is_public boolean
)
returns public.scholar_profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result public.scholar_profiles;
begin
  if not (select public.has_app_role('admin'::public.app_role)) then
    raise exception 'Admin role required' using errcode = '42501';
  end if;

  if p_is_public and not p_verified then
    raise exception 'A public scholar profile must be verified' using errcode = '23514';
  end if;

  update public.scholar_profiles
  set verified = p_verified,
      is_public = p_is_public,
      verified_at = case when p_verified then statement_timestamp() else null end,
      verified_by = case when p_verified then (select public.editorial_actor_id()) else null end,
      public_at = case when p_is_public then statement_timestamp() else null end
  where user_id = p_user_id
  returning * into v_result;

  if not found then
    raise exception 'Scholar profile not found' using errcode = 'P0002';
  end if;

  return v_result;
end;
$$;

create or replace function public.create_scholar_insight_draft(
  p_guidance_item_id uuid
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select public.editorial_actor_id());
  v_result public.scholar_insights;
begin
  if v_actor is null or not (select public.has_app_role('scholar'::public.app_role)) then
    raise exception 'Scholar role required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.guidance_items gi
    where gi.id = p_guidance_item_id and gi.active
  ) then
    raise exception 'Active guidance item not found' using errcode = 'P0002';
  end if;

  select si.*
  into v_result
  from public.scholar_insights si
  where si.guidance_item_id = p_guidance_item_id
    and si.scholar_id = v_actor
    and si.status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
  order by si.updated_at desc
  limit 1;

  if found then
    raise exception 'A working insight already exists; reload before editing'
      using errcode = '40001';
  end if;

  insert into public.scholar_insights (guidance_item_id, scholar_id)
  values (p_guidance_item_id, v_actor)
  returning * into v_result;

  return v_result;
end;
$$;

create or replace function public.create_scholar_replacement_draft(
  p_published_insight_id uuid
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select public.editorial_actor_id());
  v_published public.scholar_insights;
  v_result public.scholar_insights;
begin
  if v_actor is null or not (select public.has_app_role('scholar'::public.app_role)) then
    raise exception 'Scholar role required' using errcode = '42501';
  end if;

  select si.*
  into v_published
  from public.scholar_insights si
  join public.guidance_items gi on gi.id = si.guidance_item_id
  where si.id = p_published_insight_id
    and si.scholar_id = v_actor
    and si.status = 'published'::public.insight_status
    and gi.active
  for share of si;

  if not found then
    raise exception 'Active published insight not found' using errcode = 'P0002';
  end if;

  select si.*
  into v_result
  from public.scholar_insights si
  where si.guidance_item_id = v_published.guidance_item_id
    and si.scholar_id = v_actor
    and si.status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
  order by si.updated_at desc
  limit 1;

  if found then
    return v_result;
  end if;

  insert into public.scholar_insights (
    guidance_item_id,
    scholar_id,
    supersedes_insight_id,
    body_ar,
    body_en,
    reference_material
  ) values (
    v_published.guidance_item_id,
    v_actor,
    v_published.id,
    v_published.body_ar,
    v_published.body_en,
    v_published.reference_material
  )
  on conflict (guidance_item_id, scholar_id)
    where status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
  do nothing
  returning * into v_result;

  if found then
    return v_result;
  end if;

  select si.*
  into strict v_result
  from public.scholar_insights si
  where si.guidance_item_id = v_published.guidance_item_id
    and si.scholar_id = v_actor
    and si.status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
  order by si.updated_at desc
  limit 1;

  return v_result;
end;
$$;

create or replace function public.save_scholar_insight_draft(
  p_insight_id uuid,
  p_body_ar text,
  p_body_en text,
  p_reference_material jsonb,
  p_expected_revision_number integer
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select public.editorial_actor_id());
  v_is_scholar boolean := (select public.has_app_role('scholar'::public.app_role));
  v_is_admin boolean := (select public.has_app_role('admin'::public.app_role));
  v_result public.scholar_insights;
begin
  if v_actor is null or not (v_is_scholar or v_is_admin) then
    raise exception 'Active scholar or admin role required' using errcode = '42501';
  end if;

  if p_expected_revision_number is null or p_expected_revision_number < 1 then
    raise exception 'A valid expected revision is required' using errcode = '22023';
  end if;

  if p_body_ar is null or octet_length(p_body_ar) > 100000 then
    raise exception 'Arabic draft is missing or too large' using errcode = '22023';
  end if;

  if p_body_en is not null and octet_length(p_body_en) > 100000 then
    raise exception 'English draft is too large' using errcode = '22023';
  end if;

  if not coalesce(
    (select public.is_valid_scholar_reference_material(p_reference_material)),
    false
  ) then
    raise exception 'References require a bounded label/title and optional HTTPS URL'
      using errcode = '22023';
  end if;

  update public.scholar_insights si
  set body_ar = p_body_ar,
      body_en = nullif(btrim(p_body_en), ''),
      reference_material = p_reference_material
  where si.id = p_insight_id
    and si.status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
    and si.revision_number = p_expected_revision_number
    and (
      (si.scholar_id = v_actor and v_is_scholar)
      or v_is_admin
    )
  returning si.* into v_result;

  if not found then
    raise exception 'Draft changed or actor is not permitted; reload before saving'
      using errcode = '40001';
  end if;

  return v_result;
end;
$$;

create or replace function public.review_scholar_insight_translation(
  p_insight_id uuid,
  p_body_en text,
  p_expected_revision_number integer
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select public.editorial_actor_id());
  v_is_scholar boolean := (select public.has_app_role('scholar'::public.app_role));
  v_is_admin boolean := (select public.has_app_role('admin'::public.app_role));
  v_result public.scholar_insights;
begin
  if v_actor is null or not (v_is_scholar or v_is_admin) then
    raise exception 'Active scholar or admin role required' using errcode = '42501';
  end if;

  if p_body_en is null or btrim(p_body_en) = '' then
    raise exception 'Reviewed English must not be blank' using errcode = '23514';
  end if;

  if p_expected_revision_number is null or p_expected_revision_number < 1 then
    raise exception 'A valid expected revision is required' using errcode = '22023';
  end if;

  update public.scholar_insights si
  set body_en = btrim(p_body_en),
      translation_status = 'reviewed'::public.translation_status,
      translation_reviewed_at = statement_timestamp(),
      translation_reviewed_by = v_actor
  where si.id = p_insight_id
    and si.status = 'draft'::public.insight_status
    and si.translation_status = 'generated'::public.translation_status
    and si.revision_number = p_expected_revision_number
    and btrim(si.body_ar) <> ''
    and (
      (si.scholar_id = v_actor and v_is_scholar)
      or v_is_admin
    )
  returning si.* into v_result;

  if not found then
    raise exception 'Draft changed or is not reviewable; reload before reviewing'
      using errcode = '40001';
  end if;

  return v_result;
end;
$$;

create or replace function public.submit_scholar_insight(
  p_insight_id uuid,
  p_expected_revision_number integer
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select public.editorial_actor_id());
  v_is_scholar boolean := (select public.has_app_role('scholar'::public.app_role));
  v_is_admin boolean := (select public.has_app_role('admin'::public.app_role));
  v_result public.scholar_insights;
begin
  if v_actor is null or not (v_is_scholar or v_is_admin) then
    raise exception 'Active scholar or admin role required' using errcode = '42501';
  end if;

  if p_expected_revision_number is null or p_expected_revision_number < 1 then
    raise exception 'A valid expected revision is required' using errcode = '22023';
  end if;

  update public.scholar_insights si
  set status = 'submitted'::public.insight_status,
      reviewed_source_hash = gi.source_hash,
      submitted_at = statement_timestamp()
  from public.guidance_items gi
  where si.id = p_insight_id
    and si.guidance_item_id = gi.id
    and gi.active
    and si.status = 'draft'::public.insight_status
    and si.revision_number = p_expected_revision_number
    and si.translation_status = 'reviewed'::public.translation_status
    and btrim(si.body_ar) <> ''
    and si.body_en is not null
    and btrim(si.body_en) <> ''
    and (
      (si.scholar_id = v_actor and v_is_scholar)
      or v_is_admin
    )
  returning si.* into v_result;

  if not found then
    raise exception 'Insight changed, is not ready, or actor is not permitted'
      using errcode = '40001';
  end if;

  return v_result;
end;
$$;

create or replace function public.publish_scholar_insight(
  p_insight_id uuid
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select public.editorial_actor_id());
  v_target public.scholar_insights;
  v_result public.scholar_insights;
begin
  if not (select public.has_app_role('admin'::public.app_role)) then
    raise exception 'Admin role required' using errcode = '42501';
  end if;

  select si.*
  into v_target
  from public.scholar_insights si
  where si.id = p_insight_id
  for update;

  if not found or v_target.status <> 'submitted'::public.insight_status then
    raise exception 'Submitted insight not found' using errcode = 'P0002';
  end if;

  -- The old public row is archived in the same transaction, so readers never
  -- observe a half-published replacement.
  update public.scholar_insights si
  set status = 'archived'::public.insight_status,
      archived_at = statement_timestamp(),
      archived_by = v_actor
  where si.guidance_item_id = v_target.guidance_item_id
    and si.scholar_id = v_target.scholar_id
    and si.status = 'published'::public.insight_status
    and si.id <> v_target.id;

  update public.scholar_insights si
  set status = 'published'::public.insight_status,
      published_at = statement_timestamp(),
      published_by = v_actor
  where si.id = p_insight_id
  returning si.* into v_result;

  update public.guidance_items gi
  set needs_review = false,
      updated_at = statement_timestamp()
  where gi.id = v_result.guidance_item_id
    and gi.source_hash = v_result.reviewed_source_hash;

  return v_result;
end;
$$;

create or replace function public.archive_scholar_insight(
  p_insight_id uuid
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result public.scholar_insights;
begin
  if not (select public.has_app_role('admin'::public.app_role)) then
    raise exception 'Admin role required' using errcode = '42501';
  end if;

  update public.scholar_insights si
  set status = 'archived'::public.insight_status,
      archived_at = statement_timestamp(),
      archived_by = (select public.editorial_actor_id())
  where si.id = p_insight_id
    and si.status <> 'archived'::public.insight_status
  returning si.* into v_result;

  if not found then
    raise exception 'Active insight not found' using errcode = 'P0002';
  end if;

  return v_result;
end;
$$;

create or replace function public.save_generated_scholar_translation(
  p_insight_id uuid,
  p_body_en text,
  p_provider text,
  p_model text,
  p_requested_by uuid,
  p_expected_revision_number integer
)
returns public.scholar_insights
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result public.scholar_insights;
begin
  -- This RPC is service-role only. The supplied actor is independently checked
  -- and is retained in immutable revision history.
  if not exists (
    select 1
    from public.user_roles ur
    where ur.user_id = p_requested_by
      and (
        ur.role = 'admin'::public.app_role
        or (
          ur.role = 'scholar'::public.app_role
          and exists (
            select 1 from public.scholar_insights owned
            where owned.id = p_insight_id and owned.scholar_id = p_requested_by
          )
        )
      )
  ) then
    raise exception 'Translation requester is not permitted' using errcode = '42501';
  end if;

  if p_body_en is null or btrim(p_body_en) = '' then
    raise exception 'Generated English must not be blank' using errcode = '23514';
  end if;

  if p_expected_revision_number is null or p_expected_revision_number < 1 then
    raise exception 'A valid expected revision is required' using errcode = '22023';
  end if;

  perform set_config('app.editorial_actor_id', p_requested_by::text, true);

  update public.scholar_insights si
  set body_en = btrim(p_body_en),
      translation_status = 'generated'::public.translation_status,
      translation_provider = nullif(btrim(p_provider), ''),
      translation_model = nullif(btrim(p_model), ''),
      translation_generated_at = statement_timestamp(),
      translation_reviewed_at = null,
      translation_reviewed_by = null
  where si.id = p_insight_id
    and si.status = 'draft'::public.insight_status
    and si.revision_number = p_expected_revision_number
    and btrim(si.body_ar) <> ''
  returning si.* into v_result;

  if not found then
    raise exception 'Draft changed during translation; generate again'
      using errcode = '40001';
  end if;

  -- Deliberately no status change: generated text can never publish itself.
  return v_result;
end;
$$;

create or replace function public.sync_guidance_manifest(p_manifest jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_received integer;
  v_inserted integer;
  v_changed integer;
  v_retired integer;
begin
  if p_manifest is null or jsonb_typeof(p_manifest) <> 'array' then
    raise exception 'Manifest must be a JSON array' using errcode = '22023';
  end if;

  v_received := jsonb_array_length(p_manifest);
  if v_received = 0 or v_received > 10000 then
    raise exception 'Manifest item count is outside the safe range' using errcode = '22023';
  end if;

  -- Serialise syncs and keep staging/upsert/retirement in one transaction.
  perform pg_advisory_xact_lock(hashtext('yaqeen.guidance_manifest.sync'));

  -- Replace any caller-created temp relation with the exact constrained shape
  -- expected by this SECURITY DEFINER function.
  drop table if exists pg_temp.guidance_sync_stage;

  create temporary table guidance_sync_stage (
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
    primary key (situation_id, verse_key),
    check (source_hash ~ '^[0-9a-f]{64}$')
  ) on commit drop;

  begin
    insert into guidance_sync_stage (
      situation_id, verse_key, title_en, title_ar, context_en, context_ar,
      surah_name_en, surah_name_ar, verse_ar, verse_en, source_hash
    )
    select
      btrim(entry ->> 'situation_id'),
      btrim(entry ->> 'verse_key'),
      btrim(entry ->> 'title_en'),
      btrim(entry ->> 'title_ar'),
      btrim(entry ->> 'context_en'),
      btrim(entry ->> 'context_ar'),
      btrim(entry ->> 'surah_name_en'),
      btrim(entry ->> 'surah_name_ar'),
      btrim(entry ->> 'verse_ar'),
      btrim(entry ->> 'verse_en'),
      btrim(entry ->> 'source_hash')
    from jsonb_array_elements(p_manifest) as manifest(entry);
  exception
    when unique_violation then
      raise exception 'Manifest contains duplicate situation_id + verse_key entries'
        using errcode = '22023';
    when not_null_violation or check_violation then
      raise exception 'Manifest contains missing or invalid required fields'
        using errcode = '22023';
  end;

  if (select count(*) from pg_temp.guidance_sync_stage) <> v_received then
    raise exception 'Manifest could not be staged completely' using errcode = '22023';
  end if;

  select count(*)
  into v_inserted
  from pg_temp.guidance_sync_stage stage
  left join public.guidance_items existing
    on existing.situation_id = stage.situation_id
   and existing.verse_key = stage.verse_key
  where existing.id is null;

  select count(*)
  into v_changed
  from pg_temp.guidance_sync_stage stage
  join public.guidance_items existing
    on existing.situation_id = stage.situation_id
   and existing.verse_key = stage.verse_key
  where existing.source_hash <> stage.source_hash;

  select count(*)
  into v_retired
  from public.guidance_items existing
  where existing.active
    and not exists (
      select 1
      from pg_temp.guidance_sync_stage stage
      where stage.situation_id = existing.situation_id
        and stage.verse_key = existing.verse_key
    );

  insert into public.guidance_items (
    situation_id, verse_key, title_en, title_ar, context_en, context_ar,
    surah_name_en, surah_name_ar, verse_ar, verse_en, source_hash,
    source_revision, needs_review, active, source_changed_at,
    last_synced_at, retired_at, updated_at
  )
  select
    stage.situation_id, stage.verse_key, stage.title_en, stage.title_ar,
    stage.context_en, stage.context_ar, stage.surah_name_en, stage.surah_name_ar,
    stage.verse_ar, stage.verse_en, stage.source_hash,
    1, true, true, statement_timestamp(), statement_timestamp(), null,
    statement_timestamp()
  from pg_temp.guidance_sync_stage stage
  on conflict (situation_id, verse_key) do update set
    title_en = excluded.title_en,
    title_ar = excluded.title_ar,
    context_en = excluded.context_en,
    context_ar = excluded.context_ar,
    surah_name_en = excluded.surah_name_en,
    surah_name_ar = excluded.surah_name_ar,
    verse_ar = excluded.verse_ar,
    verse_en = excluded.verse_en,
    source_revision = case
      when guidance_items.source_hash <> excluded.source_hash
        then guidance_items.source_revision + 1
      else guidance_items.source_revision
    end,
    needs_review = guidance_items.needs_review
      or not guidance_items.active
      or guidance_items.source_hash <> excluded.source_hash,
    source_changed_at = case
      when not guidance_items.active
        or guidance_items.source_hash <> excluded.source_hash
        then statement_timestamp()
      else guidance_items.source_changed_at
    end,
    source_hash = excluded.source_hash,
    active = true,
    retired_at = null,
    last_synced_at = statement_timestamp(),
    updated_at = statement_timestamp();

  -- Missing source rows are retired, never deleted. Existing insight rows,
  -- including the published version, are untouched by manifest sync.
  update public.guidance_items existing
  set active = false,
      retired_at = coalesce(existing.retired_at, statement_timestamp()),
      last_synced_at = statement_timestamp(),
      updated_at = statement_timestamp()
  where existing.active
    and not exists (
      select 1
      from pg_temp.guidance_sync_stage stage
      where stage.situation_id = existing.situation_id
        and stage.verse_key = existing.verse_key
    );

  return jsonb_build_object(
    'received', v_received,
    'inserted', v_inserted,
    'changed', v_changed,
    'retired', v_retired,
    'synced_at', statement_timestamp()
  );
end;
$$;

-- RLS: role membership is readable by the owner and admins, never writable.
create policy user_roles_select_own
on public.user_roles for select
to authenticated
using (user_id = (select auth.uid()));

create policy user_roles_select_admin
on public.user_roles for select
to authenticated
using ((select public.has_app_role('admin'::public.app_role)));

-- A public profile must satisfy both explicit visibility and verification.
create policy scholar_profiles_select_public
on public.scholar_profiles for select
to anon, authenticated
using (is_public and verified);

create policy scholar_profiles_select_own
on public.scholar_profiles for select
to authenticated
using (user_id = (select auth.uid()));

create policy scholar_profiles_select_admin
on public.scholar_profiles for select
to authenticated
using ((select public.has_app_role('admin'::public.app_role)));

create policy scholar_profiles_update_own
on public.scholar_profiles for update
to authenticated
using (
  user_id = (select auth.uid())
  and (select public.has_app_role('scholar'::public.app_role))
)
with check (
  user_id = (select auth.uid())
  and (select public.has_app_role('scholar'::public.app_role))
);

-- Guidance source copy is already public inside the app. Queue access to retired
-- items is restricted to editorial users.
create policy guidance_items_select_active
on public.guidance_items for select
to anon, authenticated
using (active);

create policy guidance_items_select_editorial
on public.guidance_items for select
to authenticated
using (
  (select public.has_app_role('admin'::public.app_role))
  or (select public.has_app_role('scholar'::public.app_role))
);

create policy scholar_insights_select_published
on public.scholar_insights for select
to anon, authenticated
using (
  status = 'published'::public.insight_status
  and exists (
    select 1
    from public.guidance_items gi
    where gi.id = guidance_item_id
      and gi.active
  )
  and exists (
    select 1
    from public.scholar_profiles sp
    where sp.user_id = scholar_id
      and sp.is_public
      and sp.verified
  )
);

create policy scholar_insights_select_own_work
on public.scholar_insights for select
to authenticated
using (
  scholar_id = (select auth.uid())
  and status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
  and (select public.has_app_role('scholar'::public.app_role))
);

create policy scholar_insights_select_admin
on public.scholar_insights for select
to authenticated
using ((select public.has_app_role('admin'::public.app_role)));

create policy scholar_insights_insert_own_draft
on public.scholar_insights for insert
to authenticated
with check (
  scholar_id = (select auth.uid())
  and status = 'draft'::public.insight_status
  and (select public.has_app_role('scholar'::public.app_role))
  and exists (
    select 1 from public.guidance_items gi
    where gi.id = guidance_item_id and gi.active
  )
);

create policy scholar_insights_update_own_work
on public.scholar_insights for update
to authenticated
using (
  scholar_id = (select auth.uid())
  and status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
  and (select public.has_app_role('scholar'::public.app_role))
)
with check (
  scholar_id = (select auth.uid())
  and status in ('draft'::public.insight_status, 'submitted'::public.insight_status)
  and (select public.has_app_role('scholar'::public.app_role))
);

create policy scholar_insight_revisions_select_own
on public.scholar_insight_revisions for select
to authenticated
using (
  scholar_id = (select auth.uid())
  and (select public.has_app_role('scholar'::public.app_role))
);

create policy scholar_insight_revisions_select_admin
on public.scholar_insight_revisions for select
to authenticated
using ((select public.has_app_role('admin'::public.app_role)));

create policy editorial_audit_log_select_admin
on public.editorial_audit_log for select
to authenticated
using ((select public.has_app_role('admin'::public.app_role)));

-- Least-privilege table grants. Column grants prevent a scholar from changing
-- authorization, publication, verification, or translation-review state.
revoke all on table public.user_roles from anon, authenticated;
revoke all on table public.scholar_profiles from anon, authenticated;
revoke all on table public.guidance_items from anon, authenticated;
revoke all on table public.scholar_insights from anon, authenticated;
revoke all on table public.scholar_insight_revisions from anon, authenticated;
revoke all on table public.editorial_audit_log from anon, authenticated;

grant select (
  user_id, display_name_en, display_name_ar, title_en, title_ar, bio_en, bio_ar,
  avatar_path, instagram_url, youtube_url, facebook_url, tiktok_url, website_url,
  verified, is_public, updated_at
) on public.scholar_profiles to anon;

grant select (
  id, situation_id, verse_key, title_en, title_ar, active
) on public.guidance_items to anon;

grant select (
  id, guidance_item_id, scholar_id, body_ar, body_en, reference_material,
  status, translation_status, published_at, updated_at
) on public.scholar_insights to anon;

grant select on table public.scholar_profiles to authenticated;
grant select on table public.guidance_items to authenticated;
grant select on table public.scholar_insights to authenticated;
grant select on table public.user_roles to authenticated;
grant select on table public.scholar_insight_revisions to authenticated;
grant select on table public.editorial_audit_log to authenticated;

grant update (
  display_name_en, display_name_ar, title_en, title_ar, bio_en, bio_ar,
  instagram_url, youtube_url, facebook_url, tiktok_url, website_url
) on public.scholar_profiles to authenticated;

-- All insight mutations go through the revision-checked SECURITY DEFINER RPCs
-- below. Direct table writes stay revoked so a custom client cannot bypass CAS.

revoke all on function public.editorial_actor_id() from public, anon, authenticated;
revoke all on function public.has_app_role(public.app_role) from public, anon, authenticated;
revoke all on function public.editorial_actor_role() from public, anon, authenticated;
revoke all on function public.storage_object_owner_id(text) from public, anon, authenticated;
revoke all on function public.is_valid_scholar_reference_material(jsonb)
  from public, anon, authenticated;
revoke all on function public.reject_immutable_history_change() from public, anon, authenticated;
revoke all on function public.prepare_scholar_profile_update() from public, anon, authenticated;
revoke all on function public.prepare_scholar_insight_write() from public, anon, authenticated;
revoke all on function public.capture_scholar_insight_revision() from public, anon, authenticated;
revoke all on function public.capture_editorial_audit_event() from public, anon, authenticated;
revoke all on function public.admin_assign_user_role(uuid, public.app_role) from public, anon, authenticated;
revoke all on function public.admin_upsert_scholar_profile(
  uuid, text, text, text, text, text, text, text, text, text, text, text, text
) from public, anon, authenticated;
revoke all on function public.admin_set_scholar_profile_visibility(uuid, boolean, boolean)
  from public, anon, authenticated;
revoke all on function public.create_scholar_insight_draft(uuid)
  from public, anon, authenticated;
revoke all on function public.create_scholar_replacement_draft(uuid)
  from public, anon, authenticated;
revoke all on function public.save_scholar_insight_draft(uuid, text, text, jsonb, integer)
  from public, anon, authenticated;
revoke all on function public.review_scholar_insight_translation(uuid, text, integer)
  from public, anon, authenticated;
revoke all on function public.submit_scholar_insight(uuid, integer)
  from public, anon, authenticated;
revoke all on function public.publish_scholar_insight(uuid)
  from public, anon, authenticated;
revoke all on function public.archive_scholar_insight(uuid)
  from public, anon, authenticated;
revoke all on function public.save_generated_scholar_translation(
  uuid, text, text, text, uuid, integer
)
  from public, anon, authenticated;
revoke all on function public.sync_guidance_manifest(jsonb)
  from public, anon, authenticated;

grant execute on function public.has_app_role(public.app_role) to authenticated;
grant execute on function public.is_valid_scholar_reference_material(jsonb)
  to authenticated, service_role;
grant execute on function public.admin_assign_user_role(uuid, public.app_role) to authenticated;
grant execute on function public.admin_upsert_scholar_profile(
  uuid, text, text, text, text, text, text, text, text, text, text, text, text
) to authenticated;
grant execute on function public.admin_set_scholar_profile_visibility(uuid, boolean, boolean)
  to authenticated;
grant execute on function public.create_scholar_insight_draft(uuid) to authenticated;
grant execute on function public.create_scholar_replacement_draft(uuid) to authenticated;
grant execute on function public.save_scholar_insight_draft(uuid, text, text, jsonb, integer)
  to authenticated;
grant execute on function public.review_scholar_insight_translation(uuid, text, integer)
  to authenticated;
grant execute on function public.submit_scholar_insight(uuid, integer) to authenticated;
grant execute on function public.publish_scholar_insight(uuid) to authenticated;
grant execute on function public.archive_scholar_insight(uuid) to authenticated;

grant execute on function public.save_generated_scholar_translation(
  uuid, text, text, text, uuid, integer
)
  to service_role;
grant execute on function public.sync_guidance_manifest(jsonb) to service_role;

create view public.public_scholar_profiles
with (security_invoker = true)
as
select
  sp.user_id as scholar_id,
  sp.display_name_en,
  sp.display_name_ar,
  sp.title_en,
  sp.title_ar,
  sp.bio_en,
  sp.bio_ar,
  sp.verified,
  sp.avatar_path,
  sp.instagram_url,
  sp.youtube_url,
  sp.facebook_url,
  sp.tiktok_url,
  sp.website_url,
  sp.updated_at
from public.scholar_profiles sp
where sp.is_public and sp.verified;

revoke all on table public.public_scholar_profiles from public;
grant select on table public.public_scholar_profiles to anon, authenticated;

-- Public read model for the app/dashboard. security_invoker keeps all underlying
-- table RLS policies active.
create view public.published_scholar_content
with (security_invoker = true)
as
select
  si.id,
  si.guidance_item_id,
  gi.situation_id,
  gi.verse_key,
  gi.title_en as situation_title_en,
  gi.title_ar as situation_title_ar,
  si.scholar_id,
  sp.display_name_en,
  sp.display_name_ar,
  sp.title_en,
  sp.title_ar,
  sp.bio_en,
  sp.bio_ar,
  sp.verified,
  sp.avatar_path,
  sp.instagram_url,
  sp.youtube_url,
  sp.facebook_url,
  sp.tiktok_url,
  sp.website_url,
  si.body_ar,
  si.body_en,
  si.reference_material,
  si.translation_status,
  si.published_at,
  si.updated_at
from public.scholar_insights si
join public.guidance_items gi on gi.id = si.guidance_item_id
join public.scholar_profiles sp on sp.user_id = si.scholar_id
where si.status = 'published'::public.insight_status
  and gi.active
  and sp.is_public
  and sp.verified;

revoke all on table public.published_scholar_content from public;
grant select on table public.published_scholar_content to anon, authenticated;

-- Avatars are intentionally public media: the iOS client can render the standard
-- Storage public URL without attaching an Authorization header. Writes remain
-- limited to the owner's UUID folder. Never place drafts or private media here.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'scholar-avatars',
  'scholar-avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy scholar_avatars_select_public
on storage.objects for select
to anon, authenticated
using (
  bucket_id = 'scholar-avatars'
  and exists (
    select 1
    from public.scholar_profiles sp
    where sp.user_id = public.storage_object_owner_id(name)
      and sp.verified
      and sp.is_public
  )
);

create policy scholar_avatars_select_own
on storage.objects for select
to authenticated
using (
  bucket_id = 'scholar-avatars'
  and public.storage_object_owner_id(name) = (select auth.uid())
  and (select public.has_app_role('scholar'::public.app_role))
);

create policy scholar_avatars_insert_own
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'scholar-avatars'
  and public.storage_object_owner_id(name) = (select auth.uid())
  and (select public.has_app_role('scholar'::public.app_role))
);

-- Scholars deliberately have no UPDATE or DELETE policy. A replacement must be
-- uploaded at a new unique path, then assigned through scholar_profiles; changing
-- avatar_path makes the profile private/unverified until an admin reviews it.
-- Only the admin policy below may overwrite or remove an existing public object.

create policy scholar_avatars_admin_all
on storage.objects for all
to authenticated
using (
  bucket_id = 'scholar-avatars'
  and (select public.has_app_role('admin'::public.app_role))
)
with check (
  bucket_id = 'scholar-avatars'
  and (select public.has_app_role('admin'::public.app_role))
);

grant execute on function public.storage_object_owner_id(text) to anon, authenticated;
