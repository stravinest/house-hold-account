-- Migration: 033_add_check_user_exists_rpc.sql
-- 초대 시 이메일로 사용자 존재 여부를 확인하는 RPC 함수
-- security definer를 사용하여 RLS 정책을 우회

CREATE OR REPLACE FUNCTION house.check_user_exists_by_email(target_email TEXT)
RETURNS TABLE (
  id UUID,
  email TEXT,
  display_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = house, public
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.email, p.display_name
  FROM house.profiles p
  WHERE p.email = LOWER(TRIM(target_email))
  LIMIT 1;
END;
$$;

-- 인증된 사용자만 호출 가능
GRANT EXECUTE ON FUNCTION house.check_user_exists_by_email(TEXT) TO authenticated;
