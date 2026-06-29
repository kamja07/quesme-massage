-- 테스트 계정 로그인 오류 수정
-- 원인: SQL로 만든 auth.users의 token 계열 컬럼이 NULL → GoTrue 로그인 시
--       "Database error querying schema" 발생. NULL → '' 로 채우면 해결.
update auth.users set
  confirmation_token         = coalesce(confirmation_token, ''),
  recovery_token             = coalesce(recovery_token, ''),
  email_change               = coalesce(email_change, ''),
  email_change_token_new     = coalesce(email_change_token_new, ''),
  email_change_token_current = coalesce(email_change_token_current, ''),
  phone_change               = coalesce(phone_change, ''),
  phone_change_token         = coalesce(phone_change_token, ''),
  reauthentication_token     = coalesce(reauthentication_token, '')
where email like 'massage%@thaimate.app'
   or email like 'customer%@guest.quesme.app';

-- 확인: select email from auth.users where email like 'massage%@thaimate.app' order by email;
