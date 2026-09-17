-- Private, opt-in Haneen library backup. Each user owns one versioned document.
-- No Qur'an/audio blobs or credentials are stored here: values are small JSON
-- records encoded as strings by the app. Account deletion cascades to this row.
create function public.haneen_library_payload_valid(candidate jsonb)
returns boolean
language plpgsql
immutable
security invoker
set search_path = ''
as $$
begin
  if candidate is null or pg_catalog.jsonb_typeof(candidate) <> 'object' then
    return false;
  end if;
  if pg_catalog.octet_length(candidate::text) > 5242880 then
    return false;
  end if;
  return (select pg_catalog.count(*) <= 30000
            and coalesce(pg_catalog.bool_and(pg_catalog.jsonb_typeof(value) = 'string'), true)
          from pg_catalog.jsonb_each(candidate));
end;
$$;

create table public.account_library_documents (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 1 check (revision > 0),
  payload jsonb not null default '{}'::jsonb
    check (public.haneen_library_payload_valid(payload)),
  updated_at timestamptz not null default pg_catalog.now()
);

alter table public.account_library_documents enable row level security;
alter table public.account_library_documents force row level security;
revoke all on table public.account_library_documents from public, anon, authenticated;
grant select, insert, update on table public.account_library_documents to authenticated;
grant all on table public.account_library_documents to service_role;

create policy "Read own Haneen library" on public.account_library_documents
for select to authenticated
using ((select auth.uid()) = user_id
  and coalesce((select auth.jwt() ->> 'is_anonymous'), 'false') <> 'true');
create policy "Create own Haneen library" on public.account_library_documents
for insert to authenticated
with check ((select auth.uid()) = user_id
  and coalesce((select auth.jwt() ->> 'is_anonymous'), 'false') <> 'true');
create policy "Update own Haneen library" on public.account_library_documents
for update to authenticated
using ((select auth.uid()) = user_id
  and coalesce((select auth.jwt() ->> 'is_anonymous'), 'false') <> 'true')
with check ((select auth.uid()) = user_id
  and coalesce((select auth.jwt() ->> 'is_anonymous'), 'false') <> 'true');

-- The supplied user ID is an identity assertion, never an authorization source.
-- It prevents an account switch during SDK token refresh from writing the old
-- user's pending local data into the newly signed-in user's account.
create function public.compare_and_swap_account_library(
  p_user_id uuid,
  p_expected_revision bigint,
  p_payload jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  owner_id uuid := auth.uid();
  result_revision bigint;
  result_payload jsonb;
begin
  if owner_id is null or p_user_id is distinct from owner_id
      or coalesce(auth.jwt() ->> 'is_anonymous', 'false') = 'true' then
    raise exception 'Account identity changed or sign-in is required' using errcode = '42501';
  end if;
  if p_expected_revision is null or p_expected_revision < 0
      or p_expected_revision = 9223372036854775807 then
    raise exception 'Invalid library revision' using errcode = '22023';
  end if;
  if not public.haneen_library_payload_valid(p_payload) then
    raise exception 'Library must be a string-valued object within 5 MiB and 30000 records'
      using errcode = '22023';
  end if;

  if p_expected_revision = 0 then
    insert into public.account_library_documents (user_id, revision, payload)
    values (owner_id, 1, p_payload)
    on conflict (user_id) do nothing
    returning revision, payload into result_revision, result_payload;
  else
    update public.account_library_documents
    set payload = p_payload, revision = revision + 1, updated_at = pg_catalog.now()
    where user_id = owner_id and revision = p_expected_revision
    returning revision, payload into result_revision, result_payload;
  end if;

  if not found then return null; end if;
  return pg_catalog.jsonb_build_object('revision', result_revision, 'payload', result_payload);
end;
$$;

revoke all on function public.haneen_library_payload_valid(jsonb) from public, anon, authenticated;
grant execute on function public.haneen_library_payload_valid(jsonb) to authenticated, service_role;
revoke all on function public.compare_and_swap_account_library(uuid, bigint, jsonb)
  from public, anon, authenticated;
grant execute on function public.compare_and_swap_account_library(uuid, bigint, jsonb)
  to authenticated;

comment on table public.account_library_documents is
  'Private opt-in Haneen saved library. Owner-only RLS; deletion cascades from auth.users.';
