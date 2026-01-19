-- 멤버 수에 따라 is_shared를 자동으로 동기화하는 트리거
-- 멤버가 2명 이상이면 공유 가계부, 1명이면 개인 가계부

-- is_shared 동기화 함수
CREATE OR REPLACE FUNCTION house.sync_ledger_is_shared()
RETURNS TRIGGER AS $$
DECLARE
  member_count INT;
  should_be_shared BOOLEAN;
BEGIN
  -- INSERT/UPDATE의 경우 NEW.ledger_id, DELETE의 경우 OLD.ledger_id 사용
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
$$ LANGUAGE plpgsql;

-- 기존 트리거 삭제 (존재하면)
DROP TRIGGER IF EXISTS sync_is_shared_on_member_insert ON house.ledger_members;
DROP TRIGGER IF EXISTS sync_is_shared_on_member_delete ON house.ledger_members;

-- 멤버 추가 시 트리거
CREATE TRIGGER sync_is_shared_on_member_insert
  AFTER INSERT ON house.ledger_members
  FOR EACH ROW
  EXECUTE FUNCTION house.sync_ledger_is_shared();

-- 멤버 삭제 시 트리거
CREATE TRIGGER sync_is_shared_on_member_delete
  AFTER DELETE ON house.ledger_members
  FOR EACH ROW
  EXECUTE FUNCTION house.sync_ledger_is_shared();
