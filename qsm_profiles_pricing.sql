-- 마사지사 프로필 필드 + 요금 등급(일반/프리티 시간별 정액). 한 번 실행.

-- 프로필 필드 (프리티 프로필: 나이·키·몸무게·사이즈·사진 갤러리)
alter table qsm_providers add column if not exists age    int;
alter table qsm_providers add column if not exists height int;     -- cm
alter table qsm_providers add column if not exists weight int;     -- kg
alter table qsm_providers add column if not exists stats  text;    -- 사이즈 예: 34-24-36
alter table qsm_providers add column if not exists photos jsonb default '[]'::jsonb;

-- 시술 등급: all(공통) | regular(일반) | pretty(프리티)
alter table qsm_services add column if not exists tier text not null default 'all';

-- ===== 데모 시드 (샵이 콘솔에서 직접 수정/추가) =====
-- 프리티 마사지사 샘플 스탯
update qsm_providers set age=24, height=165, weight=48, stats='34-24-36' where store_slug='pattaya-ibalso' and login_id='ploy';
update qsm_providers set age=22, height=168, weight=50, stats='33-23-35' where store_slug='pattaya-ibalso' and login_id='mint';
update qsm_providers set age=25, height=170, weight=51, stats='35-25-36'
  where store_slug='pattaya-ibalso' and tier='pretty' and login_id like 'massage%' and age is null;

-- 기존 시술 → 일반 요금으로 표시
update qsm_services set tier='regular' where store_slug='pattaya-ibalso' and tier='all';

-- 프리티 시간별 정액 요금 (예시값 — 샵이 콘솔에서 직접 입력/수정)
insert into qsm_services (store_slug, name, duration_min, price, tier, sort)
select v.* from (values
  ('pattaya-ibalso','프리티 마사지',60,700,'pretty',101),
  ('pattaya-ibalso','프리티 마사지',90,1000,'pretty',102),
  ('pattaya-ibalso','프리티 마사지',120,1400,'pretty',103)
) as v(store_slug,name,duration_min,price,tier,sort)
where not exists (select 1 from qsm_services s where s.store_slug='pattaya-ibalso' and s.tier='pretty');
