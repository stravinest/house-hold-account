-- profiles SELECT 정책의 순환 참조 문제 해결
-- ledger_members를 직접 조회하는 대신 SECURITY DEFINER 함수 사용

-- 1. 같은 가계부 멤버의 user_id 목록을 반환하는 함수
CREATE OR REPLACE FUNCTION house.get_same_ledger_member_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = house, public
STABLE
AS $$
  SELECT DISTINCT lm2.user_id
  FROM house.ledger_members lm1
  JOIN house.ledger_members lm2 ON lm1.ledger_id = lm2.ledger_id
  WHERE lm1.user_id = (select auth.uid());
$$;

-- 2. profiles SELECT 정책 수정
DROP POLICY IF EXISTS "profiles_select_same_ledger_members" ON house.profiles;

CREATE POLICY "profiles_select_same_ledger_members" ON house.profiles
FOR SELECT USING (
  id = (select auth.uid())
  OR id IN (SELECT house.get_same_ledger_member_ids())
);

-- 함수 실행 권한 부여
GRANT EXECUTE ON FUNCTION house.get_same_ledger_member_ids() TO authenticated;
