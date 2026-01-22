-- 결제수단에 소유자(owner_user_id) 필드 추가
-- 공유 가계부에서 멤버별 결제수단 관리를 위함

-- 1. owner_user_id 컬럼 추가 (nullable로 먼저 추가)
ALTER TABLE house.payment_methods 
ADD COLUMN owner_user_id UUID REFERENCES house.profiles(id);

-- 2. 기존 데이터 마이그레이션
-- 개인 가계부: 가계부 생성자를 소유자로 설정
UPDATE house.payment_methods pm
SET owner_user_id = l.created_by
FROM house.ledgers l
WHERE pm.ledger_id = l.id
  AND l.is_shared = false;

-- 공유 가계부: 첫 번째 멤버를 소유자로 설정 (임시)
UPDATE house.payment_methods pm
SET owner_user_id = (
  SELECT user_id 
  FROM house.ledger_members 
  WHERE ledger_id = pm.ledger_id 
  ORDER BY joined_at ASC 
  LIMIT 1
)
WHERE owner_user_id IS NULL;

-- 3. NOT NULL 제약조건 추가
ALTER TABLE house.payment_methods 
ALTER COLUMN owner_user_id SET NOT NULL;

-- 4. 인덱스 추가 (성능 최적화)
CREATE INDEX idx_payment_methods_owner 
ON house.payment_methods(owner_user_id);

CREATE INDEX idx_payment_methods_ledger_owner 
ON house.payment_methods(ledger_id, owner_user_id);

-- 5. RLS 정책 수정
-- 기존 정책 삭제
DROP POLICY IF EXISTS "payment_methods_select" ON house.payment_methods;
DROP POLICY IF EXISTS "payment_methods_insert" ON house.payment_methods;
DROP POLICY IF EXISTS "payment_methods_update" ON house.payment_methods;
DROP POLICY IF EXISTS "payment_methods_delete" ON house.payment_methods;

-- 새로운 정책 생성
-- SELECT: 가계부 멤버는 모든 결제수단 조회 가능
CREATE POLICY "payment_methods_select"
ON house.payment_methods FOR SELECT
USING (
  ledger_id IN (
    SELECT ledger_id 
    FROM house.ledger_members 
    WHERE user_id = auth.uid()
  )
);

-- INSERT: 가계부 멤버는 자신의 결제수단만 생성 가능
CREATE POLICY "payment_methods_insert"
ON house.payment_methods FOR INSERT
WITH CHECK (
  ledger_id IN (
    SELECT ledger_id 
    FROM house.ledger_members 
    WHERE user_id = auth.uid()
  )
  AND owner_user_id = auth.uid()
);

-- UPDATE: 자신이 소유한 결제수단만 수정 가능
CREATE POLICY "payment_methods_update"
ON house.payment_methods FOR UPDATE
USING (owner_user_id = auth.uid())
WITH CHECK (owner_user_id = auth.uid());

-- DELETE: 자신이 소유한 결제수단만 삭제 가능
CREATE POLICY "payment_methods_delete"
ON house.payment_methods FOR DELETE
USING (owner_user_id = auth.uid());
