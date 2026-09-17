do $test$
declare
  a uuid; b uuid; result jsonb; blocked boolean; n integer;
begin
  a := gen_random_uuid(); b := gen_random_uuid();
  begin
  insert into auth.users(id, email, role, aud) values
    (a, a::text || '@example.invalid','authenticated','authenticated'),
    (b, b::text || '@example.invalid','authenticated','authenticated');
  perform set_config('request.jwt.claims', jsonb_build_object('sub',a,'role','authenticated','is_anonymous',false)::text,true);
  set local role authenticated;
  result := public.compare_and_swap_account_library(a,0,'{"note/a":"private-a"}');
  if result->>'revision' <> '1' then raise exception 'initial CAS failed'; end if;
  if public.compare_and_swap_account_library(a,0,'{"bad":"stale"}') is not null then raise exception 'stale create overwrote'; end if;
  result := public.compare_and_swap_account_library(a,1,'{"note/a":"edited-a"}');
  if result->>'revision' <> '2' then raise exception 'update CAS failed'; end if;
  if public.compare_and_swap_account_library(a,1,'{"bad":"stale"}') is not null then raise exception 'stale update overwrote'; end if;
  blocked := false;
  begin perform public.compare_and_swap_account_library(b,0,'{"note":"cross-user"}'); exception when insufficient_privilege then blocked := true; end;
  if not blocked then raise exception 'RPC identity bypass'; end if;
  perform set_config('request.jwt.claims', jsonb_build_object('sub',b,'role','authenticated','is_anonymous',false)::text,true);
  select count(*) into n from public.account_library_documents where user_id=a;
  if n <> 0 then raise exception 'cross-user SELECT leak'; end if;
  update public.account_library_documents set payload='{"bad":"cross-user"}' where user_id=a;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'cross-user UPDATE bypass'; end if;
  blocked := false;
  begin insert into public.account_library_documents(user_id,payload) values(a,'{}'); exception when insufficient_privilege then blocked := true; end;
  if not blocked then raise exception 'cross-user INSERT bypass'; end if;
  result := public.compare_and_swap_account_library(b,0,'{"note/b":"private-b"}');
  if result->>'revision' <> '1' then raise exception 'second owner write failed'; end if;
  blocked := false;
  begin perform public.compare_and_swap_account_library(b,1,'{"bad":42}'); exception when invalid_parameter_value then blocked:=true; end;
  if not blocked then raise exception 'non-string payload accepted'; end if;
  perform set_config('request.jwt.claims', jsonb_build_object('sub',b,'role','authenticated','is_anonymous',true)::text,true);
  select count(*) into n from public.account_library_documents;
  if n <> 0 then raise exception 'anonymous-auth SELECT leak'; end if;
  blocked:=false;
  begin perform public.compare_and_swap_account_library(b,1,'{}'); exception when insufficient_privilege then blocked:=true; end;
  if not blocked then raise exception 'anonymous-auth RPC bypass'; end if;
  reset role;
  set local role anon;
  blocked:=false;
  begin perform 1 from public.account_library_documents; exception when insufficient_privilege then blocked:=true; end;
  if not blocked then raise exception 'anon SELECT permitted'; end if;
  reset role;
  delete from auth.users where id=a;
  select count(*) into n from public.account_library_documents where user_id=a;
  if n<>0 then raise exception 'account deletion did not cascade'; end if;
  select count(*) into n from public.account_library_documents where user_id=b;
  if n<>1 then raise exception 'account deletion affected other owner'; end if;
  raise exception 'All isolation checks passed; roll back synthetic data' using errcode='ZX001';
  exception when sqlstate 'ZX001' then null;
  end;
end;
$test$;
