begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public;

select plan(32);

-- Deterministic local-only identities. The transaction is rolled back at EOF.
insert into auth.users (
  id, aud, role, email, encrypted_password, raw_app_meta_data,
  raw_user_meta_data, created_at, updated_at
) values
  (
    '11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated',
    'editorial-admin@example.invalid', '', '{}'::jsonb, '{}'::jsonb,
    statement_timestamp(), statement_timestamp()
  ),
  (
    '22222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated',
    'editorial-scholar@example.invalid', '', '{}'::jsonb, '{}'::jsonb,
    statement_timestamp(), statement_timestamp()
  ),
  (
    '33333333-3333-4333-8333-333333333333', 'authenticated', 'authenticated',
    'editorial-ordinary@example.invalid', '', '{}'::jsonb, '{}'::jsonb,
    statement_timestamp(), statement_timestamp()
  ),
  (
    '44444444-4444-4444-8444-444444444444', 'authenticated', 'authenticated',
    'editorial-second-scholar@example.invalid', '', '{}'::jsonb, '{}'::jsonb,
    statement_timestamp(), statement_timestamp()
  );

insert into public.user_roles (user_id, role, assigned_by) values
  (
    '11111111-1111-4111-8111-111111111111',
    'admin'::public.app_role,
    '11111111-1111-4111-8111-111111111111'
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'scholar'::public.app_role,
    '11111111-1111-4111-8111-111111111111'
  ),
  (
    '44444444-4444-4444-8444-444444444444',
    'scholar'::public.app_role,
    '11111111-1111-4111-8111-111111111111'
  );

insert into public.scholar_profiles (
  user_id, display_name_en, verified, is_public,
  verified_at, verified_by, public_at
) values (
  '22222222-2222-4222-8222-222222222222',
  'Authorization Test Scholar',
  true,
  true,
  statement_timestamp(),
  '11111111-1111-4111-8111-111111111111',
  statement_timestamp()
);

insert into public.scholar_profiles (user_id, display_name_en)
values (
  '44444444-4444-4444-8444-444444444444',
  'Second Authorization Test Scholar'
);

insert into public.guidance_items (
  id, situation_id, verse_key, title_en, title_ar, context_en, context_ar,
  surah_name_en, surah_name_ar, verse_ar, verse_en, source_hash,
  active, retired_at
) values
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'AuthorizationActiveOne', '1:1',
    'Active one', 'نشط واحد', 'Context', 'سياق', 'Al-Fatihah', 'الفاتحة',
    'بِسْمِ اللَّهِ', 'In the name of Allah', repeat('a', 64), true, null
  ),
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2', 'AuthorizationActiveTwo', '1:2',
    'Active two', 'نشط اثنان', 'Context', 'سياق', 'Al-Fatihah', 'الفاتحة',
    'الْحَمْدُ لِلَّهِ', 'All praise is for Allah', repeat('b', 64), true, null
  ),
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3', 'AuthorizationInactive', '1:3',
    'Inactive', 'غير نشط', 'Context', 'سياق', 'Al-Fatihah', 'الفاتحة',
    'الرَّحْمَٰنِ الرَّحِيمِ', 'The Most Compassionate', repeat('c', 64),
    false, statement_timestamp()
  );

-- Build one live publication, its working replacement, and a second submitted
-- row through the same trigger/RPC transitions used by production.
set local app.editorial_actor_id = '22222222-2222-4222-8222-222222222222';

insert into public.scholar_insights (
  id, guidance_item_id, scholar_id, body_ar, reference_material
) values (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  '22222222-2222-4222-8222-222222222222',
  'نص عربي منشور',
  '[]'::jsonb
);

do $$
begin
  perform public.save_scholar_insight_draft(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
    'نص عربي منشور',
    'Published English text',
    '[]'::jsonb,
    1
  );
  perform public.review_scholar_insight_translation(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1', 'Published English text', 2
  );
  perform public.submit_scholar_insight(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1', 3
  );
end;
$$;

-- A second scholar can work on the same guidance item without sharing drafts.
set local app.editorial_actor_id = '44444444-4444-4444-8444-444444444444';
insert into public.scholar_insights (
  id, guidance_item_id, scholar_id, body_ar, reference_material
) values (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  '44444444-4444-4444-8444-444444444444',
  'مسودة الباحث الثاني',
  '[]'::jsonb
);
set local app.editorial_actor_id = '22222222-2222-4222-8222-222222222222';

set local app.editorial_actor_id = '11111111-1111-4111-8111-111111111111';
do $$
begin
  perform public.publish_scholar_insight('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1');
end;
$$;

set local app.editorial_actor_id = '22222222-2222-4222-8222-222222222222';
insert into public.scholar_insights (
  id, guidance_item_id, scholar_id, body_ar, reference_material
) values
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
    '22222222-2222-4222-8222-222222222222',
    'مسودة بديلة',
    '[]'::jsonb
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2',
    '22222222-2222-4222-8222-222222222222',
    'نص عربي ثان',
    '[]'::jsonb
  );

do $$
begin
  perform public.save_scholar_insight_draft(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',
    'نص عربي ثان',
    'Second reviewed English text',
    '[]'::jsonb,
    1
  );
  perform public.review_scholar_insight_translation(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3', 'Second reviewed English text', 2
  );
  perform public.submit_scholar_insight(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3', 3
  );
end;
$$;

-- An anonymous reader sees the active, published row and nothing in progress.
set local request.jwt.claims = '{"role":"anon"}';
set local role anon;
select results_eq(
  $$select count(*)::bigint from public.scholar_insights$$,
  array[1::bigint],
  'anon sees only the active published insight'
);
select results_eq(
  $$select count(*)::bigint from public.scholar_insights where status in ('draft', 'submitted')$$,
  array[0::bigint],
  'anon cannot read working insights'
);
select results_eq(
  $$select count(*)::bigint from public.public_scholar_profiles$$,
  array[1::bigint],
  'anon can read the verified public profile view with column-scoped grants'
);
select results_eq(
  $$select count(*)::bigint from public.published_scholar_content$$,
  array[1::bigint],
  'anon can read active published content through the iOS public view'
);
reset role;

-- A role-less authenticated user gets public rows but no editorial work or role writes.
set local request.jwt.claims = '{"role":"authenticated","sub":"33333333-3333-4333-8333-333333333333"}';
set local role authenticated;
select results_eq(
  $$select count(*)::bigint from public.scholar_insights where status in ('draft', 'submitted')$$,
  array[0::bigint],
  'ordinary authenticated user cannot read working insights'
);
select throws_ok(
  $$insert into public.user_roles (user_id, role) values (
      '33333333-3333-4333-8333-333333333333', 'admin'::public.app_role
    )$$,
  '42501',
  'permission denied for table user_roles',
  'ordinary authenticated user cannot promote itself'
);
reset role;

-- The active scholar sees both working rows before revocation.
set local request.jwt.claims = '{"role":"authenticated","sub":"22222222-2222-4222-8222-222222222222"}';
set local role authenticated;
select results_eq(
  $$select count(*)::bigint from public.scholar_insights where status in ('draft', 'submitted')$$,
  array[2::bigint],
  'active scholar can read their own working insights'
);
select results_eq(
  $$select count(*)::bigint from public.scholar_insights
    where scholar_id = '44444444-4444-4444-8444-444444444444'
      and status in ('draft', 'submitted')$$,
  array[0::bigint],
  'a scholar cannot read another scholar''s working insights'
);
select results_eq(
  $$select (public.create_scholar_replacement_draft(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1'
    )).id::text$$,
  array['bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2'::text],
  'replacement creation returns an existing working copy without overwriting it'
);
select throws_ok(
  $$select public.create_scholar_insight_draft(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1'
    )$$,
  '40001',
  'A working insight already exists; reload before editing',
  'generic draft creation cannot overwrite or silently reuse concurrent work'
);
reset role;

set local request.jwt.claims = '{"role":"authenticated","sub":"44444444-4444-4444-8444-444444444444"}';
set local role authenticated;
select results_eq(
  $$select count(*)::bigint from public.scholar_insights where status in ('draft', 'submitted')$$,
  array[1::bigint],
  'a second scholar can read their own working insight'
);
select results_eq(
  $$select count(*)::bigint from public.scholar_insights
    where scholar_id = '22222222-2222-4222-8222-222222222222'
      and status in ('draft', 'submitted')$$,
  array[0::bigint],
  'a second scholar cannot read the first scholar''s working insights'
);
reset role;

set local request.jwt.claims = '{"role":"authenticated","sub":"22222222-2222-4222-8222-222222222222"}';
delete from public.user_roles
where user_id = '22222222-2222-4222-8222-222222222222';

set local role authenticated;
select results_eq(
  $$select count(*)::bigint from public.scholar_insights where status in ('draft', 'submitted')$$,
  array[0::bigint],
  'role revocation immediately hides former working insights'
);
select throws_ok(
  $$select public.save_scholar_insight_draft(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'محاولة تعديل', null, '[]'::jsonb, 1
    )$$,
  '42501',
  'Active scholar or admin role required',
  'revoked scholar cannot save a former draft'
);
select throws_ok(
  $$select public.review_scholar_insight_translation(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'Attempted review', 1
    )$$,
  '42501',
  'Active scholar or admin role required',
  'revoked scholar cannot review a former draft'
);
select throws_ok(
  $$select public.submit_scholar_insight(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 1
    )$$,
  '42501',
  'Active scholar or admin role required',
  'revoked scholar cannot submit a former draft'
);
reset role;

insert into public.user_roles (user_id, role, assigned_by) values (
  '22222222-2222-4222-8222-222222222222',
  'scholar'::public.app_role,
  '11111111-1111-4111-8111-111111111111'
);

set local role authenticated;
select throws_ok(
  $$select public.save_scholar_insight_draft(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'مسودة بديلة', null, '[1]'::jsonb, 1
    )$$,
  '22023',
  'References require a bounded label/title and optional HTTPS URL',
  'scholar cannot save malformed or unsafe public references'
);
select lives_ok(
  $$select public.save_scholar_insight_draft(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'مسودة محدثة', null, '[]'::jsonb, 1
    )$$,
  'active scholar can save a valid replacement draft'
);
select throws_ok(
  $$select public.save_scholar_insight_draft(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'كتابة قديمة', null, '[]'::jsonb, 1
    )$$,
  '40001',
  'Draft changed or actor is not permitted; reload before saving',
  'a stale dashboard tab cannot overwrite a newer draft revision'
);
reset role;

set local role service_role;
select lives_ok(
  $$select public.save_generated_scholar_translation(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
      'Fresh generated translation',
      'test-provider',
      'test-model',
      '22222222-2222-4222-8222-222222222222',
      2
    )$$,
  'translation service saves against the exact Arabic revision'
);
select throws_ok(
  $$select public.save_generated_scholar_translation(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
      'Stale generated translation',
      'test-provider',
      'test-model',
      '22222222-2222-4222-8222-222222222222',
      2
    )$$,
  '40001',
  'Draft changed during translation; generate again',
  'translation service rejects stale provider output'
);
reset role;

set local role authenticated;
select throws_ok(
  $$select public.review_scholar_insight_translation(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'Stale human review', 2
    )$$,
  '40001',
  'Draft changed or is not reviewable; reload before reviewing',
  'human review rejects a stale dashboard revision'
);
select lives_ok(
  $$select public.review_scholar_insight_translation(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'Reviewed current translation', 3
    )$$,
  'human review accepts the current generated revision'
);
select throws_ok(
  $$select public.submit_scholar_insight(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 3
    )$$,
  '40001',
  'Insight changed, is not ready, or actor is not permitted',
  'a stale dashboard revision cannot submit newer reviewed content'
);
select throws_ok(
  $$select public.publish_scholar_insight('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3')$$,
  '42501',
  'Admin role required',
  'scholar cannot publish a submitted insight'
);
reset role;

set local request.jwt.claims = '{"role":"authenticated","sub":"11111111-1111-4111-8111-111111111111"}';
set local role authenticated;
select lives_ok(
  $$select public.publish_scholar_insight('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3')$$,
  'admin can publish a reviewed submission'
);
reset role;

set local request.jwt.claims = '{"role":"authenticated","sub":"22222222-2222-4222-8222-222222222222"}';
set local role authenticated;
select throws_ok(
  $$select public.archive_scholar_insight('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3')$$,
  '42501',
  'Admin role required',
  'scholar cannot archive a published insight'
);
select throws_ok(
  $$select public.create_scholar_insight_draft('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3')$$,
  'P0002',
  'Active guidance item not found',
  'scholar cannot create a draft for inactive guidance'
);
reset role;

set local request.jwt.claims = '{"role":"authenticated","sub":"11111111-1111-4111-8111-111111111111"}';
set local role authenticated;
select lives_ok(
  $$select public.archive_scholar_insight('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3')$$,
  'admin can archive a published insight'
);
select lives_ok(
  $$select public.admin_upsert_scholar_profile(
      '22222222-2222-4222-8222-222222222222',
      'Authorization Test Scholar', null, null, null, null, null,
      '22222222-2222-4222-8222-222222222222/reviewed-replacement.jpg'
    )$$,
  'admin can stage a new portrait path for review'
);
select results_eq(
  $$select (verified::text || ':' || is_public::text)
    from public.scholar_profiles
    where user_id = '22222222-2222-4222-8222-222222222222'$$,
  array['false:false'::text],
  'changing a portrait path makes the profile private until explicit review'
);
reset role;

update public.guidance_items
set active = false,
    retired_at = statement_timestamp()
where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';

set local request.jwt.claims = '{"role":"anon"}';
set local role anon;
select results_eq(
  $$select count(*)::bigint from public.scholar_insights$$,
  array[0::bigint],
  'anon cannot read a published insight after its guidance item is retired'
);
reset role;

select * from finish();
rollback;
