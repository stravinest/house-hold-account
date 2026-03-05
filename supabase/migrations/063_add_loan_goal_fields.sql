-- 대출 목표 기능을 위한 asset_goals 테이블 컬럼 추가
ALTER TABLE house.asset_goals
  ADD COLUMN IF NOT EXISTS goal_type TEXT NOT NULL DEFAULT 'asset'
    CHECK (goal_type IN ('asset', 'loan')),
  ADD COLUMN IF NOT EXISTS loan_amount INTEGER,
  ADD COLUMN IF NOT EXISTS repayment_method TEXT
    CHECK (repayment_method IN ('equal_principal_interest', 'equal_principal', 'bullet', 'graduated')),
  ADD COLUMN IF NOT EXISTS annual_interest_rate REAL,
  ADD COLUMN IF NOT EXISTS start_date DATE,
  ADD COLUMN IF NOT EXISTS monthly_payment INTEGER,
  ADD COLUMN IF NOT EXISTS is_manual_payment BOOLEAN DEFAULT false;

COMMENT ON COLUMN house.asset_goals.goal_type IS '목표 유형: asset(자산 목표), loan(대출 상환 목표)';
COMMENT ON COLUMN house.asset_goals.loan_amount IS '대출 원금 (goal_type=loan 일 때 사용)';
COMMENT ON COLUMN house.asset_goals.repayment_method IS '상환 방식: equal_principal_interest(원리금균등), equal_principal(원금균등), bullet(만기일시), graduated(체증식)';
COMMENT ON COLUMN house.asset_goals.annual_interest_rate IS '연이율 (예: 3.5 -> 3.5%)';
COMMENT ON COLUMN house.asset_goals.start_date IS '대출 시작일';
COMMENT ON COLUMN house.asset_goals.monthly_payment IS '월 납입금 (is_manual_payment=true 일 때 직접 입력값)';
COMMENT ON COLUMN house.asset_goals.is_manual_payment IS '월 납입금 수동 입력 여부';
