ALTER TABLE asset_goals 
  ALTER COLUMN target_date DROP NOT NULL;

ALTER TABLE asset_goals 
  DROP CONSTRAINT IF EXISTS valid_target_date;

ALTER TABLE asset_goals 
  ADD CONSTRAINT valid_target_date 
  CHECK (target_date IS NULL OR target_date > CURRENT_DATE);
