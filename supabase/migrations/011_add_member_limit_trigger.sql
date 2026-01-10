-- 가계부 멤버 수 제한 트리거
-- 최대 2명까지만 멤버 추가 가능

-- 멤버 수 제한 확인 함수
CREATE OR REPLACE FUNCTION check_member_limit()
RETURNS TRIGGER AS $$
DECLARE
  member_count INT;
  max_members INT := 2;
BEGIN
  -- 현재 멤버 수 조회
  SELECT COUNT(*) INTO member_count
  FROM ledger_members
  WHERE ledger_id = NEW.ledger_id;

  -- 제한 초과 시 에러
  IF member_count >= max_members THEN
    RAISE EXCEPTION '가계부 멤버는 최대 %명까지만 가능합니다.', max_members;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 기존 트리거 삭제 (존재하면)
DROP TRIGGER IF EXISTS enforce_member_limit ON ledger_members;

-- 멤버 추가 전 트리거 생성
CREATE TRIGGER enforce_member_limit
  BEFORE INSERT ON ledger_members
  FOR EACH ROW
  EXECUTE FUNCTION check_member_limit();

-- 초대받은 사용자가 멤버로 추가될 수 있도록 RLS 정책 수정
-- 기존 정책 삭제
DROP POLICY IF EXISTS "소유자/관리자는 멤버를 추가할 수 있음" ON ledger_members;

-- 새 정책: 소유자/관리자 또는 pending 초대를 받은 사용자
CREATE POLICY "소유자/관리자/초대받은자는 멤버를 추가할 수 있음"
  ON ledger_members FOR INSERT
  WITH CHECK (
    -- 소유자/관리자
    ledger_id IN (
      SELECT lm.ledger_id FROM ledger_members lm
      WHERE lm.user_id = auth.uid() AND lm.role IN ('owner', 'admin')
    )
    -- 또는 pending 초대를 받은 사용자
    OR (
      user_id = auth.uid()
      AND EXISTS (
        SELECT 1 FROM ledger_invites li
        JOIN profiles p ON p.email = li.invitee_email
        WHERE li.ledger_id = ledger_members.ledger_id
          AND p.id = auth.uid()
          AND li.status = 'pending'
          AND li.expires_at > NOW()
      )
    )
  );
