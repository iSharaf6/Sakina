-- Optional product feedback survives deletion without an account identifier.
create table public.account_exit_feedback (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  reason text not null default '' check (reason in ('', 'not_using', 'technical', 'privacy', 'another_app', 'other')),
  feedback text not null default '' check (char_length(feedback) <= 1000)
);
alter table public.account_exit_feedback enable row level security;
revoke all on public.account_exit_feedback from anon, authenticated;
grant insert, select, delete on public.account_exit_feedback to service_role;
