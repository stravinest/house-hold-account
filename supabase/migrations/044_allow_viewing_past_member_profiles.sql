-- 탈퇴한 멤버의 거래 내역에서도 사용자 이름 표시
-- 같은 가계부의 거래를 생성한 사용자 프로필 조회 허용

-- 1. 같은 가계부의 거래를 생성한 user_id 목록을 반환하는 함수
CREATE OR REPLACE FUNCTION house.get_same_ledger_transaction_user_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = house, public
STABLE
AS $$
  -- 내가 속한 가계부들
  SELECT DISTINCT t.user_id
  FROM house.ledger_members lm
  JOIN house.transactions t ON lm.ledger_id = t.ledger_id
  WHERE lm.user_id = (select auth.uid());
$$;

-- 2. profiles SELECT 정책 수정
DROP POLICY IF EXISTS "profiles_select_same_ledger_members" ON house.profiles;

CREATE POLICY "profiles_select_same_ledger_members" ON house.profiles
FOR SELECT USING (
  id = (select auth.uid())                                  -- 본인
  OR id IN (SELECT house.get_same_ledger_member_ids())      -- 같은 가계부의 현재 멤버
  OR id IN (SELECT house.get_same_ledger_transaction_user_ids()) -- 같은 가계부에 거래를 생성한 사용자 (탈퇴했더라도)
);

-- 함수 실행 권한 부여
GRANT EXECUTE ON FUNCTION house.get_same_ledger_transaction_user_ids() TO authenticated;
