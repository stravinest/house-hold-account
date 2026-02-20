-- 트리거 함수에 SECURITY DEFINER 추가
-- 문제: 가계부 owner가 아닌 사용자(초대받은 멤버)가 ledger_members를 변경할 때
-- 트리거 내부의 UPDATE house.ledgers가 RLS 정책(owner_id = auth.uid())에 의해 차단됨
-- 해결: SECURITY DEFINER로 함수 소유자 권한으로 실행하여 RLS 우회

CREATE OR REPLACE FUNCTION house.sync_ledger_is_shared()
RETURNS TRIGGER AS $$
DECLARE
  member_count INT;
  should_be_shared BOOLEAN;
BEGIN
  IF TG_OP = 'DELETE' THEN
    SELECT COUNT(*) INTO member_count
    FROM house.ledger_members
    WHERE ledger_id = OLD.ledger_id;

    should_be_shared := member_count >= 2;

    UPDATE house.ledgers
    SET is_shared = should_be_shared
    WHERE id = OLD.ledger_id AND is_shared != should_be_shared;
  ELSE
    SELECT COUNT(*) INTO member_count
    FROM house.ledger_members
    WHERE ledger_id = NEW.ledger_id;

    should_be_shared := member_count >= 2;

    UPDATE house.ledgers
    SET is_shared = should_be_shared
    WHERE id = NEW.ledger_id AND is_shared != should_be_shared;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기존 데이터 보정: member_count >= 2 인데 is_shared = false 인 가계부 수정
UPDATE house.ledgers l
SET is_shared = true
WHERE is_shared = false
AND (SELECT COUNT(*) FROM house.ledger_members lm WHERE lm.ledger_id = l.id) >= 2;

-- 반대 케이스도 보정: member_count < 2 인데 is_shared = true 인 가계부 수정
UPDATE house.ledgers l
SET is_shared = false
WHERE is_shared = true
AND (SELECT COUNT(*) FROM house.ledger_members lm WHERE lm.ledger_id = l.id) < 2;
