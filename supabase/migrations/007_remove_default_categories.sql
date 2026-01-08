-- category_id를 nullable로 변경
ALTER TABLE transactions ALTER COLUMN category_id DROP NOT NULL;

-- 기본 카테고리를 사용하는 거래의 카테고리를 NULL로 설정
UPDATE transactions
SET category_id = NULL
WHERE category_id IN (SELECT id FROM categories WHERE is_default = TRUE);

-- 기존 기본 카테고리 삭제 (is_default = TRUE)
DELETE FROM categories WHERE is_default = TRUE;

-- 기본 카테고리 자동 생성 트리거 삭제
DROP TRIGGER IF EXISTS on_ledger_created_categories ON ledgers;
DROP FUNCTION IF EXISTS handle_new_ledger_categories();
