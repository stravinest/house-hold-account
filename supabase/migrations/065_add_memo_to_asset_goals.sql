-- 자산/대출 목표에 메모 필드 추가
ALTER TABLE house.asset_goals ADD COLUMN IF NOT EXISTS memo TEXT;
