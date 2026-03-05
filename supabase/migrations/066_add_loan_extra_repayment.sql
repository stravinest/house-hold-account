-- 대출 목표 추가상환 및 금리 변경 이력 컬럼 추가
ALTER TABLE house.asset_goals
  ADD COLUMN IF NOT EXISTS extra_repaid_amount INTEGER DEFAULT 0;

ALTER TABLE house.asset_goals
  ADD COLUMN IF NOT EXISTS previous_interest_rate REAL;

ALTER TABLE house.asset_goals
  ADD COLUMN IF NOT EXISTS rate_changed_at DATE;
