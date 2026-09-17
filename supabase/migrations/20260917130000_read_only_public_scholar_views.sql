-- The public scholar views are read-only surfaces. Base-table RLS already
-- blocks writes through them; remove the default write grants as well.
revoke all on public.public_scholar_profiles from anon, authenticated;
revoke all on public.published_scholar_content from anon, authenticated;
grant select on public.public_scholar_profiles to anon, authenticated;
grant select on public.published_scholar_content to anon, authenticated;
