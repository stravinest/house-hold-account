-- 015_convert_saving_to_asset.sql
-- 저축(saving) 타입을 자산(asset) 타입으로 통합

-- Step 1: 기존 'saving' 타입을 'asset'으로 변경
UPDATE transactions SET type = 'asset' WHERE type = 'saving';
UPDATE categories SET type = 'asset' WHERE type = 'saving';
UPDATE recurring_templates SET type = 'asset' WHERE type = 'saving';

-- Step 2: CHECK 제약조건 업데이트
-- transactions 테이블
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_type_check;
ALTER TABLE transactions ADD CONSTRAINT transactions_type_check 
  CHECK (type IN ('income', 'expense', 'asset'));

-- categories 테이블
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_type_check;
ALTER TABLE categories ADD CONSTRAINT categories_type_check 
  CHECK (type IN ('income', 'expense', 'asset'));

-- recurring_templates 테이블
ALTER TABLE recurring_templates DROP CONSTRAINT IF EXISTS recurring_templates_type_check;
ALTER TABLE recurring_templates ADD CONSTRAINT recurring_templates_type_check 
  CHECK (type IN ('income', 'expense', 'asset'));

-- Step 3: 기존 저축 데이터에 is_asset = true 설정
-- (기존 저축은 모두 자산으로 간주)
UPDATE transactions 
SET is_asset = true 
WHERE type = 'asset' AND is_asset IS NULL;

-- 완료 메시지
DO $$
BEGIN
  RAISE NOTICE '저축(saving) → 자산(asset) 타입 변경 완료';
END $$;
