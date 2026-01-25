-- 자동수집 결제수단의 사용자별 독립 관리를 위한 UNIQUE constraint 수정
-- 2026-01-25
--
-- 문제: 기존 UNIQUE(ledger_id, name)은 같은 가계부에서 동일한 이름의
-- 자동수집 결제수단을 서로 다른 사용자가 등록할 수 없음
--
-- 해결: 공유 결제수단과 자동수집 결제수단의 UNIQUE 조건을 분리
-- - 공유 결제수단 (can_auto_save=false): (ledger_id, name) 기준
-- - 자동수집 결제수단 (can_auto_save=true): (ledger_id, owner_user_id, name) 기준

-- 1. 기존 UNIQUE constraint 삭제
ALTER TABLE house.payment_methods
DROP CONSTRAINT IF EXISTS payment_methods_ledger_id_name_key;

-- 2. 공유 결제수단용 partial unique index
-- can_auto_save=false인 경우 같은 가계부에서 동일 이름 불가
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_shared_payment_method_name
ON house.payment_methods (ledger_id, name)
WHERE can_auto_save = false;

-- 3. 자동수집 결제수단용 partial unique index
-- can_auto_save=true인 경우 같은 가계부 + 같은 소유자에서만 동일 이름 불가
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_auto_collect_payment_method_name
ON house.payment_methods (ledger_id, owner_user_id, name)
WHERE can_auto_save = true;
