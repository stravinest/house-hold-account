-- 039_update_payment_method_sharing_policy.sql
-- 의존성: 037_add_payment_method_owner.sql 이후 적용
-- 이전 정책(037에서 생성)을 완전히 대체함
--
-- 결제수단 공유 정책 수정
-- 직접입력(can_auto_save = false): 가계부 멤버 모두 수정/삭제 가능 (공유됨)
-- 자동수집(can_auto_save = true): 소유자만 수정/삭제 가능 (개인용)
--
-- NOTE: can_auto_save 값을 true에서 false로 변경하면
-- 해당 결제수단은 공유 결제수단이 되어 다른 멤버도 수정/삭제 가능해집니다.
-- 이는 의도된 동작입니다. (소유자가 개인 결제수단을 공유로 전환하는 경우)

-- 기존 정책 삭제
DROP POLICY IF EXISTS "payment_methods_select" ON house.payment_methods;
DROP POLICY IF EXISTS "payment_methods_insert" ON house.payment_methods;
DROP POLICY IF EXISTS "payment_methods_update" ON house.payment_methods;
DROP POLICY IF EXISTS "payment_methods_delete" ON house.payment_methods;

-- 새로운 정책 생성

-- SELECT: 가계부 멤버는 모든 결제수단 조회 가능 (변경 없음)
CREATE POLICY "payment_methods_select"
ON house.payment_methods FOR SELECT
USING (
  ledger_id IN (
    SELECT ledger_id
    FROM house.ledger_members
    WHERE user_id = auth.uid()
  )
);

-- INSERT: 가계부 멤버는 결제수단 생성 가능
-- 직접입력(can_auto_save = false): 누구나 생성 가능
-- 자동수집(can_auto_save = true): 자신의 owner_user_id로만 생성 가능
CREATE POLICY "payment_methods_insert"
ON house.payment_methods FOR INSERT
WITH CHECK (
  ledger_id IN (
    SELECT ledger_id
    FROM house.ledger_members
    WHERE user_id = auth.uid()
  )
  AND (
    -- 직접입력(공유): 멤버면 생성 가능
    can_auto_save = false
    OR
    -- 자동수집(개인): 본인 소유로만 생성 가능
    (can_auto_save = true AND owner_user_id = auth.uid())
  )
);

-- UPDATE:
-- 직접입력(can_auto_save = false): 가계부 멤버 모두 수정 가능
-- 자동수집(can_auto_save = true): 소유자만 수정 가능
CREATE POLICY "payment_methods_update"
ON house.payment_methods FOR UPDATE
USING (
  -- 직접입력: 가계부 멤버면 수정 가능
  (can_auto_save = false AND ledger_id IN (
    SELECT ledger_id
    FROM house.ledger_members
    WHERE user_id = auth.uid()
  ))
  OR
  -- 자동수집: 소유자만 수정 가능
  (can_auto_save = true AND owner_user_id = auth.uid())
)
WITH CHECK (
  -- 직접입력: 가계부 멤버면 수정 가능
  (can_auto_save = false AND ledger_id IN (
    SELECT ledger_id
    FROM house.ledger_members
    WHERE user_id = auth.uid()
  ))
  OR
  -- 자동수집: 소유자만 수정 가능
  (can_auto_save = true AND owner_user_id = auth.uid())
);

-- DELETE:
-- 직접입력(can_auto_save = false): 가계부 멤버 모두 삭제 가능
-- 자동수집(can_auto_save = true): 소유자만 삭제 가능
CREATE POLICY "payment_methods_delete"
ON house.payment_methods FOR DELETE
USING (
  -- 직접입력: 가계부 멤버면 삭제 가능
  (can_auto_save = false AND ledger_id IN (
    SELECT ledger_id
    FROM house.ledger_members
    WHERE user_id = auth.uid()
  ))
  OR
  -- 자동수집: 소유자만 삭제 가능
  (can_auto_save = true AND owner_user_id = auth.uid())
);

-- 인덱스 추가 (쿼리 성능 최적화)
CREATE INDEX IF NOT EXISTS idx_payment_methods_can_auto_save
ON house.payment_methods(can_auto_save);

CREATE INDEX IF NOT EXISTS idx_payment_methods_ledger_auto_save
ON house.payment_methods(ledger_id, can_auto_save);
