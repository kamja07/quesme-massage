-- 샵 운영시간(스케줄 그리드 범위) 구조화
alter table qsm_shops add column if not exists open_time  text default '10:00';
alter table qsm_shops add column if not exists close_time text default '22:00';

update qsm_shops set open_time='10:00', close_time='22:00' where slug='pattaya-ibalso';
