-- QuesMe Massage — 매장 간판(스토어프론트): 대표 사진 9장 + 소개 + 프로모션 + 특징
alter table qsm_shops add column if not exists photos   jsonb default '[]'::jsonb;  -- 간판 사진(최대 9, 3x3) dataURL 배열
alter table qsm_shops add column if not exists intro    text;                        -- 매장 소개(한 문단)
alter table qsm_shops add column if not exists promo    text;                        -- 프로모션(눈에 띄게 표시)
alter table qsm_shops add column if not exists features jsonb default '[]'::jsonb;   -- 특징 배지 리스트(문자열 배열)
