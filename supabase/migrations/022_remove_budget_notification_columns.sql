-- 예산 관련 알림 컬럼 제거
-- 제거 대상: budget_warning_enabled, budget_exceeded_enabled
-- 유지 대상: shared_ledger_change_enabled, invite_received_enabled, invite_accepted_enabled

-- 기존 데이터는 자동으로 보존됩니다 (다른 컬럼들)
ALTER TABLE notification_settings
DROP COLUMN IF EXISTS budget_warning_enabled;

ALTER TABLE notification_settings
DROP COLUMN IF EXISTS budget_exceeded_enabled;

-- 변경 사항 확인용 주석
-- 남은 알림 설정 컬럼:
-- - shared_ledger_change_enabled
-- - invite_received_enabled
-- - invite_accepted_enabled
