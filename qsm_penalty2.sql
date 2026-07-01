-- QuesMe Massage — 마사지사가 '근무로 되돌리면' 본인 미납 벌금이 취소되도록
-- 마사지사(provider) 본인의 status='pending' 벌금 삭제 허용. (확정/납부/면제된 건은 삭제 불가)
drop policy if exists qsm_pen_self_del on qsm_penalties;
create policy qsm_pen_self_del on qsm_penalties for delete to authenticated
  using (qsm_is_provider(provider_id) and status='pending');
