-- 자산(Asset) 관리 기능 추가 마이그레이션
-- transactions 테이블에 is_asset, maturity_date 컬럼 추가
-- budgets 테이블 삭제 (예산 기능 제거)

-- 1. transactions 테이블에 자산 관련 컬럼 추가
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS is_asset BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS maturity_date DATE;

-- 2. is_asset 인덱스 추가 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_transactions_is_asset 
ON transactions(is_asset) 
WHERE is_asset = TRUE;

-- 3. maturity_date 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_transactions_maturity_date 
ON transactions(maturity_date) 
WHERE maturity_date IS NOT NULL;

-- 4. 복합 인덱스 추가 (자산 조회 최적화)
CREATE INDEX IF NOT EXISTS idx_transactions_asset_lookup
ON transactions(ledger_id, type, is_asset, date)
WHERE type = 'saving' AND is_asset = TRUE;

-- 5. budgets 테이블 삭제 (예산 기능 제거)
DROP TABLE IF EXISTS budgets CASCADE;

-- 6. 주석 추가
COMMENT ON COLUMN transactions.is_asset IS '자산으로 등록된 저축 거래 여부';
COMMENT ON COLUMN transactions.maturity_date IS '자산의 만기일 (저축 타입에서만 사용)';
