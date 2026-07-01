-- QuesMe Massage — 대시보드에 등록된 모든 마사지사(login_id) 로그인 계정을 비번 '123456'으로
-- ⚠️ 테스트 전용. 약한 비번이므로 운영 전 반드시 교체/삭제.
-- 없으면 생성(auth.users + auth.identities), 이미 있으면 비번을 123456으로 리셋.
-- 아이디 규칙: login_id + '@thaimate.app' (소문자). pgcrypto는 Supabase 기본 제공.
do $$
declare r record; em text; uid uuid;
begin
  for r in select distinct login_id from qsm_providers where login_id is not null and login_id <> '' loop
    em := lower(r.login_id) || '@thaimate.app';
    if exists (select 1 from auth.users where email = em) then
      update auth.users set encrypted_password = crypt('123456', gen_salt('bf')), updated_at = now() where email = em;
    else
      uid := gen_random_uuid();
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
        confirmation_token, recovery_token, email_change, email_change_token_new, reauthentication_token)
      values ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', em,
        crypt('123456', gen_salt('bf')), now(), now(), now(),
        '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, '', '', '', '', '');
      insert into auth.identities (id, provider_id, user_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at)
      values (gen_random_uuid(), em, uid, jsonb_build_object('sub', uid::text, 'email', em), 'email', now(), now(), now());
    end if;
  end loop;
end $$;

-- 확인: 마사지사별 로그인 계정 존재 여부
select p.name, p.login_id, (u.email is not null) as has_login
from qsm_providers p
left join auth.users u on u.email = lower(p.login_id) || '@thaimate.app'
where p.login_id is not null
order by p.sort;
