-- 파트너 샵 교체: sabai-thonglor(데모) → pattaya-ibalso(파타야 이발소)
-- 이미 qsm_schema.sql을 실행한 라이브 DB용. 한 번만 실행. 여러 번 돌려도 안전(없으면 no-op).

update qsm_providers set store_slug='pattaya-ibalso' where store_slug='sabai-thonglor';
update qsm_rooms      set store_slug='pattaya-ibalso' where store_slug='sabai-thonglor';
update qsm_services   set store_slug='pattaya-ibalso' where store_slug='sabai-thonglor';
update qsm_shifts     set store_slug='pattaya-ibalso' where store_slug='sabai-thonglor';
update qsm_bookings   set store_slug='pattaya-ibalso' where store_slug='sabai-thonglor';

update qsm_staff
  set email='pattayaboss@thaimate.app', name='Pattaya Manager', store_slug='pattaya-ibalso'
  where email='sabaiboss@thaimate.app' and store_slug='sabai-thonglor';

update qsm_shops
  set slug='pattaya-ibalso',
      names='{"ko":"파타야 이발소","en":"Pattaya Ibalso","th":"พัทยา อีบัลโซ"}'::jsonb,
      area='nakluea',
      phone=null,
      hours='10:00–22:00',
      tagline='이발·헤어·마사지 · 파타야 나클루아 · 출장 가능',
      status='active'
  where slug='sabai-thonglor';

-- 확인: select slug, names->>'ko' ko, area from qsm_shops;
