-- QuesMe Massage — 마사지사 주간 스케줄 벌금 (qsm_penalties + qsm_shops.sched)
-- 규칙: 근무일 N일(기본 2일) 전까지 수정 무료, 그 이후 기존 스케줄 수정 시 벌금.

-- 샵 스케줄 규칙: {cutoffDays:2, penalty:200}
alter table qsm_shops add column if not exists sched jsonb default '{}'::jsonb;
update qsm_shops set sched = jsonb_build_object('cutoffDays',2,'penalty',200)
where slug='pattaya-ibalso' and (sched is null or sched = '{}'::jsonb);

-- 스케줄 모델: 근무가 디폴트, 비근무(전일=off, 일부=off_slots)를 표시
--  off_slots 예: [{"s":"14:00","e":"16:00"}]  → 그 시간대만 비근무
alter table qsm_shifts add column if not exists off_slots jsonb default '[]'::jsonb;

-- 벌금 기록
create table if not exists qsm_penalties (
  id          uuid primary key default gen_random_uuid(),
  store_slug  text not null,
  provider_id uuid not null,
  work_date   date not null,             -- 벌금 대상 근무일
  amount      int  not null default 0,
  reason      text default 'late_edit',  -- late_edit(2일 이내 수정)
  status      text not null default 'pending', -- pending | waived | paid
  note        text,
  created_at  timestamptz default now()
);

alter table qsm_penalties enable row level security;

-- 조회: 직원(샵) + 본인 마사지사
drop policy if exists qsm_pen_read on qsm_penalties;
create policy qsm_pen_read on qsm_penalties for select to authenticated
  using (qsm_is_staff(store_slug) or qsm_is_provider(provider_id));
-- 생성: 본인(수정 시 자동 부과) 또는 직원
drop policy if exists qsm_pen_ins on qsm_penalties;
create policy qsm_pen_ins on qsm_penalties for insert to authenticated
  with check (qsm_is_staff(store_slug) or qsm_is_provider(provider_id));
-- 수정/삭제(면제·처리): 직원만
drop policy if exists qsm_pen_staff on qsm_penalties;
create policy qsm_pen_staff on qsm_penalties for all to authenticated
  using (qsm_is_staff(store_slug)) with check (qsm_is_staff(store_slug));

do $$ begin
  begin alter publication supabase_realtime add table qsm_penalties; exception when others then null; end;
end $$;
