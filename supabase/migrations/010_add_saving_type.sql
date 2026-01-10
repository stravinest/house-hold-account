-- 저축(saving) 타입 추가 마이그레이션
-- 거래 및 카테고리 타입에 'saving' 추가

-- 1. transactions 테이블의 type 체크 제약조건 수정
ALTER TABLE transactions
DROP CONSTRAINT IF EXISTS transactions_type_check;

ALTER TABLE transactions
ADD CONSTRAINT transactions_type_check
CHECK (type IN ('income', 'expense', 'saving'));

-- 2. categories 테이블의 type 체크 제약조건 수정
ALTER TABLE categories
DROP CONSTRAINT IF EXISTS categories_type_check;

ALTER TABLE categories
ADD CONSTRAINT categories_type_check
CHECK (type IN ('income', 'expense', 'saving'));
