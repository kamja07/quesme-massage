-- QuesMe — 매장 유형: 마사지샵 vs 룸예약(라운지·노래방·파티룸)
alter table qsm_shops add column if not exists type text not null default 'massage';  -- massage | venue
