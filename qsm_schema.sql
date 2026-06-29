-- QuesMe Massage — 단독 백엔드 (qsm_* 전용, 식당/QuesMe와 완전 분리)
-- 같은 Supabase 프로젝트(thaimate) 안이지만 테이블은 독립. 한 번에 실행 가능.

-- ========== 테이블 ==========
create table if not exists qsm_shops (
  slug       text primary key,
  names      jsonb default '{}'::jsonb,   -- 언어별 이름
  area       text,
  phone      text,
  hours      text,
  logo       text,
  tagline    text,
  status     text not null default 'active', -- active | pending
  created_at timestamptz default now()
);

create table if not exists qsm_staff (
  id         uuid primary key default gen_random_uuid(),
  email      text not null,
  store_slug text not null,                 -- '*' = 플랫폼 운영자(슈퍼)
  created_at timestamptz default now()
);

create table if not exists qsm_providers (
  id          uuid primary key default gen_random_uuid(),
  store_slug  text not null,
  name        text not null,
  login_id    text,                          -- 본인 로그인 아이디(샵이 발급)
  role        text default 'therapist',
  tier        text default 'regular',        -- pretty | regular
  freelance   boolean not null default false,
  outcall_ok  boolean not null default false,
  bio         text,
  avatar      text,
  price_extra int default 0,
  active      boolean not null default true,
  sort        int default 0,
  created_at  timestamptz default now()
);

create table if not exists qsm_rooms (
  id         uuid primary key default gen_random_uuid(),
  store_slug text not null,
  name       text not null,
  type       text not null default 'private', -- private | shared | group
  capacity   int default 1,
  active     boolean not null default true,
  sort       int default 0,
  created_at timestamptz default now()
);

create table if not exists qsm_services (
  id           uuid primary key default gen_random_uuid(),
  store_slug   text not null,
  name         text not null,
  duration_min int not null default 60,
  price        int,
  active       boolean not null default true,
  sort         int default 0,
  created_at   timestamptz default now()
);

create table if not exists qsm_bookings (
  id            uuid primary key default gen_random_uuid(),
  store_slug    text not null,
  nick          text not null,
  lang          text default 'en',
  service_id    uuid,
  provider_id   uuid,
  room_id       uuid,
  mode          text not null default 'walkin', -- walkin | reserve
  location_type text not null default 'shop',   -- shop | outcall
  address       text,
  travel_fee    int default 0,
  book_date     date default current_date,
  start_time    text,
  duration_min  int default 60,
  status        text not null default 'waiting',-- waiting | serving | done | cancelled
  cno           int,
  created_at    timestamptz default now()
);

create table if not exists qsm_shifts (
  id          uuid primary key default gen_random_uuid(),
  store_slug  text not null,
  provider_id uuid not null,
  work_date   date not null default current_date,
  start_time  text default '10:00',
  end_time    text default '22:00',
  avail       text not null default 'shop',    -- shop | outcall | both
  off         boolean not null default false,
  created_at  timestamptz default now(),
  unique (provider_id, work_date)
);

create table if not exists qsm_shop_requests (
  id           uuid primary key default gen_random_uuid(),
  name         text,
  area         text,
  contact      text,
  desired_slug text,
  owner_login  text,
  status       text not null default 'pending',
  note         text,
  created_at   timestamptz default now()
);

-- ========== 권한 함수 ==========
create or replace function qsm_is_super() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from qsm_staff s where s.store_slug='*' and s.email = (auth.jwt() ->> 'email'));
$$;

create or replace function qsm_is_staff(p_slug text) returns boolean
language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from qsm_staff s
    where s.email = (auth.jwt() ->> 'email') and (s.store_slug = p_slug or s.store_slug='*')
  );
$$;

create or replace function qsm_is_provider(p_provider uuid) returns boolean
language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from qsm_providers pr
    where pr.id = p_provider and pr.login_id is not null
      and pr.login_id = split_part(auth.jwt() ->> 'email','@',1)
  );
$$;

-- ========== RLS ==========
alter table qsm_shops         enable row level security;
alter table qsm_staff         enable row level security;
alter table qsm_providers     enable row level security;
alter table qsm_rooms         enable row level security;
alter table qsm_services      enable row level security;
alter table qsm_bookings      enable row level security;
alter table qsm_shifts        enable row level security;
alter table qsm_shop_requests enable row level security;

-- 조회: 누구나 (손님 탐색)
do $$ begin
  perform 1;
end $$;
drop policy if exists qsm_shop_read on qsm_shops;
drop policy if exists qsm_prov_read on qsm_providers;
drop policy if exists qsm_room_read on qsm_rooms;
drop policy if exists qsm_svc_read  on qsm_services;
drop policy if exists qsm_book_read on qsm_bookings;
drop policy if exists qsm_shift_read on qsm_shifts;
create policy qsm_shop_read on qsm_shops     for select to anon, authenticated using (true);
create policy qsm_prov_read on qsm_providers for select to anon, authenticated using (true);
create policy qsm_room_read on qsm_rooms     for select to anon, authenticated using (true);
create policy qsm_svc_read  on qsm_services  for select to anon, authenticated using (true);
create policy qsm_book_read on qsm_bookings  for select to anon, authenticated using (true);
create policy qsm_shift_read on qsm_shifts   for select to anon, authenticated using (true);

-- 샵: 본인 샵 수정(직원), 전체(슈퍼)
drop policy if exists qsm_shop_staff on qsm_shops;
create policy qsm_shop_staff on qsm_shops for all to authenticated using (qsm_is_staff(slug)) with check (qsm_is_staff(slug));

-- 직원 명단: 슈퍼 전체
drop policy if exists qsm_staff_admin on qsm_staff;
create policy qsm_staff_admin on qsm_staff for all to authenticated using (qsm_is_super()) with check (qsm_is_super());

-- 마사지사·룸·시술: 직원 쓰기 + 마사지사 본인 프로필 수정
drop policy if exists qsm_prov_staff on qsm_providers;
drop policy if exists qsm_prov_self  on qsm_providers;
drop policy if exists qsm_room_staff on qsm_rooms;
drop policy if exists qsm_svc_staff  on qsm_services;
create policy qsm_prov_staff on qsm_providers for all to authenticated using (qsm_is_staff(store_slug)) with check (qsm_is_staff(store_slug));
create policy qsm_prov_self  on qsm_providers for update to authenticated using (qsm_is_provider(id)) with check (qsm_is_provider(id));
create policy qsm_room_staff on qsm_rooms     for all to authenticated using (qsm_is_staff(store_slug)) with check (qsm_is_staff(store_slug));
create policy qsm_svc_staff  on qsm_services  for all to authenticated using (qsm_is_staff(store_slug)) with check (qsm_is_staff(store_slug));

-- 예약: 손님 생성/취소 + 직원 전체 + 마사지사 본인
drop policy if exists qsm_book_insert on qsm_bookings;
drop policy if exists qsm_book_anon_upd on qsm_bookings;
drop policy if exists qsm_book_staff on qsm_bookings;
drop policy if exists qsm_book_self on qsm_bookings;
create policy qsm_book_insert   on qsm_bookings for insert to anon, authenticated with check (status='waiting');
create policy qsm_book_anon_upd on qsm_bookings for update to anon using (status in ('waiting','serving')) with check (status in ('waiting','cancelled'));
create policy qsm_book_staff    on qsm_bookings for all    to authenticated using (qsm_is_staff(store_slug)) with check (qsm_is_staff(store_slug));
create policy qsm_book_self     on qsm_bookings for update to authenticated using (qsm_is_provider(provider_id)) with check (qsm_is_provider(provider_id));

-- 출근: 직원 + 마사지사 본인
drop policy if exists qsm_shift_staff on qsm_shifts;
drop policy if exists qsm_shift_self  on qsm_shifts;
create policy qsm_shift_staff on qsm_shifts for all to authenticated using (qsm_is_staff(store_slug)) with check (qsm_is_staff(store_slug));
create policy qsm_shift_self  on qsm_shifts for all to authenticated using (qsm_is_provider(provider_id)) with check (qsm_is_provider(provider_id));

-- 샵 신청: 누구나 신청(pending), 슈퍼 전체
drop policy if exists qsm_req_insert on qsm_shop_requests;
drop policy if exists qsm_req_admin  on qsm_shop_requests;
create policy qsm_req_insert on qsm_shop_requests for insert to anon, authenticated with check (status='pending');
create policy qsm_req_admin  on qsm_shop_requests for all    to authenticated using (qsm_is_super()) with check (qsm_is_super());

-- ========== realtime ==========
do $$ begin
  begin alter publication supabase_realtime add table qsm_shops;         exception when others then null; end;
  begin alter publication supabase_realtime add table qsm_providers;     exception when others then null; end;
  begin alter publication supabase_realtime add table qsm_rooms;         exception when others then null; end;
  begin alter publication supabase_realtime add table qsm_services;      exception when others then null; end;
  begin alter publication supabase_realtime add table qsm_bookings;      exception when others then null; end;
  begin alter publication supabase_realtime add table qsm_shifts;        exception when others then null; end;
  begin alter publication supabase_realtime add table qsm_shop_requests; exception when others then null; end;
end $$;

-- ========== 시드 (데모 샵 + 운영자) ==========
insert into qsm_staff (email, store_slug) values ('danny@thaimate.app','*') on conflict do nothing;

insert into qsm_shops (slug, names, area, phone, hours, tagline, status) values
  ('sabai-thonglor', '{"ko":"사바이 타이마사지 텅러","en":"Sabai Thai Massage Thonglor","th":"สบาย ไทยมาสสาจ ทองหล่อ"}'::jsonb,
   'thonglor','+66 2 000 0000','10:00–24:00','전통 타이·오일·발 · 출장 가능','active')
on conflict (slug) do nothing;

delete from qsm_providers where store_slug='sabai-thonglor';
delete from qsm_rooms      where store_slug='sabai-thonglor';
delete from qsm_services   where store_slug='sabai-thonglor';

insert into qsm_providers (store_slug, name, login_id, tier, freelance, outcall_ok, bio, price_extra, sort) values
  ('sabai-thonglor','Ploy','ploy','pretty',true, true,'Oil & aroma specialist · 5y',150,1),
  ('sabai-thonglor','Mint','mint','pretty',false,false,'Thai & foot · top rated',150,2),
  ('sabai-thonglor','Nong Ann','nongann','regular',false,false,'Thai massage · 10y',0,3),
  ('sabai-thonglor','Aoy','aoy','regular',true, true,'Shoulder & foot focus',0,4);

insert into qsm_rooms (store_slug, name, type, capacity, sort) values
  ('sabai-thonglor','Private Room 1','private',1,1),
  ('sabai-thonglor','Private Room 2','private',1,2),
  ('sabai-thonglor','Couple Room','private',2,3),
  ('sabai-thonglor','Shared Hall','shared',4,4),
  ('sabai-thonglor','Group Room','group',8,5);

insert into qsm_services (store_slug, name, duration_min, price, sort) values
  ('sabai-thonglor','Thai Massage',60,300,1),
  ('sabai-thonglor','Thai Massage',90,450,2),
  ('sabai-thonglor','Thai Massage',120,600,3),
  ('sabai-thonglor','Oil Massage',60,400,4),
  ('sabai-thonglor','Oil Massage',90,550,5),
  ('sabai-thonglor','Foot Massage',30,200,6),
  ('sabai-thonglor','Foot Massage',60,350,7);

-- 오늘 출근(데모): Ploy=샵+출장, Mint=샵, Aoy=출장
insert into qsm_shifts (store_slug, provider_id, work_date, avail)
select 'sabai-thonglor', id, current_date,
  case name when 'Ploy' then 'both' when 'Mint' then 'shop' when 'Aoy' then 'outcall' end
from qsm_providers
where store_slug='sabai-thonglor' and name in ('Ploy','Mint','Aoy');
