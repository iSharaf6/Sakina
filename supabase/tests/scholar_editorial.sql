begin;

create extension if not exists pgtap with schema extensions;
set local search_path = extensions, public;

select plan(42);

insert into public.guidance_items (
  situation_id, verse_key, title_en, title_ar, context_en, context_ar,
  surah_name_en, surah_name_ar, verse_ar, verse_en, source_hash
) values (
  'PgTapNullManifestGuard', '1:7', 'Guard', 'حماية', 'Context', 'سياق',
  'Al-Fatihah', 'الفاتحة', 'صِرَاطَ الَّذِينَ', 'The path of those', repeat('d', 64)
);

select throws_ok(
  $$select public.sync_guidance_manifest(null::jsonb)$$,
  '22023',
  'Manifest must be a JSON array',
  'a null service manifest is rejected before staging or retirement'
);
select results_eq(
  $$select count(*)::bigint from public.guidance_items
    where situation_id = 'PgTapNullManifestGuard' and active$$,
  array[1::bigint],
  'rejecting a null manifest leaves active guidance unchanged'
);

select has_table('public', 'user_roles', 'public.user_roles exists');
select has_table('public', 'scholar_profiles', 'public.scholar_profiles exists');
select has_table('public', 'guidance_items', 'public.guidance_items exists');
select has_table('public', 'scholar_insights', 'public.scholar_insights exists');
select has_table(
  'public',
  'scholar_insight_revisions',
  'public.scholar_insight_revisions exists'
);
select has_table('public', 'editorial_audit_log', 'public.editorial_audit_log exists');

select has_type('public', 'app_role', 'public.app_role exists');
select has_type('public', 'insight_status', 'public.insight_status exists');
select has_type('public', 'translation_status', 'public.translation_status exists');

select has_index(
  'public',
  'guidance_items',
  'guidance_items_identity_unique',
  'guidance identity index exists'
);
select has_index(
  'public',
  'scholar_insights',
  'scholar_insights_one_working_copy_idx',
  'one-working-copy index exists'
);
select has_index(
  'public',
  'scholar_insights',
  'scholar_insights_one_published_copy_idx',
  'one-published-copy index exists'
);
select has_index(
  'public',
  'guidance_items',
  'guidance_items_review_queue_idx',
  'review queue index exists'
);
select ok(
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'scholar_insights'
      and c.conname = 'scholar_insights_reference_material_shape'
      and c.contype = 'c'
  ),
  'public insight reference JSON has a database shape constraint'
);
select ok(
  public.is_valid_scholar_reference_material(
    '[{"id":"tafsir-1","label":"Reviewed tafsir","url":"https://example.com/source"}]'::jsonb
  ),
  'valid labelled HTTPS reference is accepted'
);
select ok(
  not public.is_valid_scholar_reference_material('[{}]'::jsonb),
  'empty reference objects are rejected'
);
select ok(
  not public.is_valid_scholar_reference_material('[1]'::jsonb),
  'non-object reference entries are rejected'
);
select ok(
  not public.is_valid_scholar_reference_material(null),
  'null reference material is rejected by the validator contract'
);
select ok(
  not public.is_valid_scholar_reference_material(
    '[{"label":"Unsafe","url":"javascript:alert(1)"}]'::jsonb
  ),
  'non-HTTPS public reference URLs are rejected'
);

select ok(
  (
    select bool_and(c.relrowsecurity)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in (
        'user_roles', 'scholar_profiles', 'guidance_items',
        'scholar_insights', 'scholar_insight_revisions', 'editorial_audit_log'
      )
  ),
  'RLS is enabled on every editorial table'
);

select ok(
  not has_function_privilege('anon', 'public.sync_guidance_manifest(jsonb)', 'EXECUTE'),
  'anon cannot synchronise the manifest'
);
select ok(
  not has_function_privilege('authenticated', 'public.sync_guidance_manifest(jsonb)', 'EXECUTE'),
  'authenticated clients cannot synchronise the manifest'
);
select ok(
  has_function_privilege('service_role', 'public.sync_guidance_manifest(jsonb)', 'EXECUTE'),
  'service role can synchronise the manifest'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.save_generated_scholar_translation(uuid,text,text,text,uuid,integer)',
    'EXECUTE'
  ),
  'anon cannot save generated translations'
);
select ok(
  not has_any_column_privilege(
    'authenticated', 'public.scholar_insights', 'INSERT'
  ),
  'authenticated clients cannot bypass draft creation with direct inserts'
);
select ok(
  not has_any_column_privilege(
    'authenticated', 'public.scholar_insights', 'UPDATE'
  ),
  'authenticated clients cannot bypass revision CAS with direct updates'
);
select ok(
  not has_column_privilege(
    'authenticated', 'public.scholar_profiles', 'avatar_path', 'UPDATE'
  ),
  'scholars cannot swap the public avatar path without administrator review'
);

select has_trigger(
  'public',
  'scholar_insight_revisions',
  'scholar_insight_revisions_immutable',
  'scholar insight revisions are immutable'
);
select has_trigger(
  'public',
  'editorial_audit_log',
  'editorial_audit_log_immutable',
  'editorial audit rows are immutable'
);

select ok(
  exists (
    select 1 from storage.buckets
    where id = 'scholar-avatars' and public
  ),
  'scholar avatar bucket is intentionally public media'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'scholar_avatars_insert_own'
  ),
  'avatar owner-folder insert policy exists'
);
select ok(
  not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'scholar_avatars_update_own'
  ),
  'scholars cannot overwrite a verified avatar in place'
);
select ok(
  not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'scholar_avatars_delete_own'
  ),
  'scholars cannot delete a verified avatar in place'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'scholar_profiles'
      and policyname = 'scholar_profiles_select_public'
  ),
  'public verified-profile policy exists'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'scholar_insights'
      and policyname = 'scholar_insights_select_published'
      and qual like '%guidance_items%'
      and qual like '%active%'
  ),
  'published-insight policy excludes retired guidance items'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'scholar_insights'
      and policyname = 'scholar_insights_update_own_work'
  ),
  'scholar-owned work update policy exists'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'scholar_insights'
      and policyname = 'scholar_insights_select_own_work'
      and qual like '%has_app_role%scholar%'
  ),
  'revoked scholars cannot select former working insights'
);
select ok(
  pg_get_functiondef(
    'public.save_scholar_insight_draft(uuid,text,text,jsonb,integer)'::regprocedure
  ) like '%Active scholar or admin role required%',
  'draft save RPC rejects actors whose editorial role was revoked'
);
select ok(
  pg_get_functiondef(
    'public.review_scholar_insight_translation(uuid,text,integer)'::regprocedure
  ) like '%Active scholar or admin role required%',
  'translation review RPC rejects actors whose editorial role was revoked'
);
select ok(
  pg_get_functiondef(
    'public.submit_scholar_insight(uuid,integer)'::regprocedure
  ) like '%Active scholar or admin role required%',
  'submission RPC rejects actors whose editorial role was revoked'
);

select * from finish();
rollback;
