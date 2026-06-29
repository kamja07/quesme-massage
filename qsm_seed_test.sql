-- QuesMe Massage — 테스트 데이터 + 로그인 계정 (마사지사 10 · 고객 10)
-- ⚠️ 테스트 전용. 비번 '123456' (약함). 운영 전 반드시 삭제/교체.
-- 실행 순서: qsm_schema.sql 먼저 → 이 파일. (danny/684807은 이미 존재, 슈퍼관리자는 스키마가 지정)

-- 1) 테스트 마사지사 앱데이터 (sabai-thonglor 소속, login_id massage1..massage10)
insert into qsm_providers (store_slug, name, login_id, tier, freelance, outcall_ok, bio, price_extra, sort)
select 'sabai-thonglor', 'Massage '||i, 'massage'||i,
       case when i%3=0 then 'pretty' else 'regular' end,
       (i%2=0), (i%2=1),
       'Test therapist '||i,
       case when i%3=0 then 100 else 0 end,
       100+i
from generate_series(1,10) as i
where not exists (select 1 from qsm_providers p where p.login_id = 'massage'||i);

-- 2) 로그인 계정 생성 (auth.users + auth.identities). 비번 123456.
--    기존 계정은 건드리지 않음(존재하면 skip). pgcrypto(crypt/gen_salt)는 Supabase 기본 제공.
do $$
declare em text; uid uuid; i int;
begin
  for i in 1..10 loop
    -- 마사지사: massage{i}@thaimate.app
    em := 'massage'||i||'@thaimate.app';
    if not exists (select 1 from auth.users where email = em) then
      uid := gen_random_uuid();
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
      values ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', em,
        crypt('123456', gen_salt('bf')), now(), now(), now(),
        '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb);
      insert into auth.identities (id, provider_id, user_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at)
      values (gen_random_uuid(), em, uid,
        jsonb_build_object('sub', uid::text, 'email', em), 'email', now(), now(), now());
    end if;

    -- 고객: customer{i}@guest.quesme.app
    em := 'customer'||i||'@guest.quesme.app';
    if not exists (select 1 from auth.users where email = em) then
      uid := gen_random_uuid();
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
      values ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', em,
        crypt('123456', gen_salt('bf')), now(), now(), now(),
        '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb);
      insert into auth.identities (id, provider_id, user_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at)
      values (gen_random_uuid(), em, uid,
        jsonb_build_object('sub', uid::text, 'email', em), 'email', now(), now(), now());
    end if;
  end loop;
end $$;

-- 확인: select email from auth.users where email like 'massage%@thaimate.app' or email like 'customer%@guest.quesme.app' order by email;
