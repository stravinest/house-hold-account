-- 반복 거래 타입에 'yearly' 옵션 추가
-- 기존: 'daily', 'weekly', 'monthly'
-- 변경: 'daily', 'monthly', 'yearly' (weekly 제거, yearly 추가)

-- 기존 CHECK 제약 조건 삭제
ALTER TABLE transactions
DROP CONSTRAINT IF EXISTS transactions_recurring_type_check;

-- 새로운 CHECK 제약 조건 추가
ALTER TABLE transactions
ADD CONSTRAINT transactions_recurring_type_check
CHECK (recurring_type IN ('daily', 'monthly', 'yearly'));
