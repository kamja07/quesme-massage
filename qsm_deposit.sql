-- QuesMe Massage — 예약금/송금슬립 인증 (qsm_bookings + qsm_shops 확장)
-- 한 번에 실행 가능. RLS 변경 없음(insert는 status='waiting' 유지, anon update가 pay_* 컬럼 갱신 허용).

-- 예약 행: 예약금/입금수단/슬립/입금상태
alter table qsm_bookings add column if not exists deposit    int  default 0;
alter table qsm_bookings add column if not exists pay_method text;                      -- thai | korea | qr
alter table qsm_bookings add column if not exists pay_slip   text;                      -- 송금 슬립 이미지(dataURL)
alter table qsm_bookings add column if not exists pay_status text default 'unpaid';     -- unpaid | submitted | confirmed

-- 샵: 입금 안내(예약금 + 태국계좌/한국계좌/QR + 안내문)
-- pay 예: {"deposit":200,
--          "thai":{"bank":"Kasikorn","acc":"xxx-x-xxxxx-x","name":"Pattaya Ibalso"},
--          "korea":{"bank":"국민","acc":"000000-00-000000","name":"홍길동"},
--          "qr":"data:image/...","note":"입금 후 슬립을 올려주세요"}
alter table qsm_shops add column if not exists pay jsonb default '{}'::jsonb;

-- 데모: 파타야 이발소 예약금 ฿200 + 안내(계좌는 콘솔에서 실제값으로 교체하세요)
update qsm_shops set pay = jsonb_build_object(
    'deposit', 200,
    'thai',  jsonb_build_object('bank','Kasikorn (데모)','acc','xxx-x-xxxxx-x','name','Pattaya Ibalso'),
    'korea', jsonb_build_object('bank','국민 (데모)','acc','000000-00-000000','name','홍길동'),
    'qr', '',
    'note', '입금 후 송금 슬립(캡처)을 올려주시면 예약이 확정됩니다.'
  )
where slug='pattaya-ibalso' and (pay is null or pay = '{}'::jsonb);
