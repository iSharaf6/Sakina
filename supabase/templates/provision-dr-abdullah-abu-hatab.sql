-- Run only after both invite-only Auth accounts exist.
-- Supply values at execution time; never replace these variables in source:
--
--   psql "$DATABASE_URL" \
--     --set=admin_user_id='<invited-admin-auth-uuid>' \
--     --set=scholar_user_id='<invited-scholar-auth-uuid>' \
--     --file=supabase/templates/provision-dr-abdullah-abu-hatab.sql

begin;

-- Bootstrap the first admin through the trusted database connection. Every
-- later role assignment should use admin_assign_user_role from an admin session.
insert into public.user_roles (user_id, role, assigned_by)
select :'admin_user_id'::uuid, 'admin'::public.app_role, :'admin_user_id'::uuid
where exists (select 1 from auth.users where id = :'admin_user_id'::uuid)
on conflict (user_id) do update
set role = excluded.role,
    assigned_by = excluded.assigned_by,
    assigned_at = statement_timestamp();

select set_config('app.editorial_actor_id', :'admin_user_id', true);

select public.admin_assign_user_role(
  :'scholar_user_id'::uuid,
  'scholar'::public.app_role
);

select public.admin_upsert_scholar_profile(
  p_user_id => :'scholar_user_id'::uuid,
  p_display_name_en => 'Dr. Abdullah Abu Hatab',
  p_instagram_url => 'https://instagram.com/Dr.AbdullahAbuHatab',
  p_facebook_url => 'https://facebook.com/Dr.AbdullahAbuHatab'
);

-- Deliberately remains unverified and private. An admin must add the supplied
-- Arabic name, real title/qualification, bios, and owner-folder avatar path,
-- then explicitly call admin_set_scholar_profile_visibility.

commit;

