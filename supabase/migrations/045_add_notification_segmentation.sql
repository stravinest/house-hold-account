-- ============================================
-- 알림 시스템 세분화 마이그레이션
-- 작성일: 2026-02-01
-- 목적: 공유 가계부 알림 세분화 및 자동수집 알림 추가
-- ============================================

-- 1. notification_settings 테이블 컬럼 추가
ALTER TABLE house.notification_settings
ADD COLUMN IF NOT EXISTS transaction_added_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS transaction_updated_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS transaction_deleted_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS auto_collect_suggested_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS auto_collect_saved_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- 기존 shared_ledger_change_enabled 값을 기반으로 세분화된 설정 초기화
-- NULL 체크를 통해 이미 마이그레이션된 경우 스킵
UPDATE house.notification_settings
SET
  transaction_added_enabled = COALESCE(transaction_added_enabled, shared_ledger_change_enabled),
  transaction_updated_enabled = COALESCE(transaction_updated_enabled, shared_ledger_change_enabled),
  transaction_deleted_enabled = COALESCE(transaction_deleted_enabled, shared_ledger_change_enabled);

-- 컬럼 설명 추가
COMMENT ON COLUMN house.notification_settings.shared_ledger_change_enabled IS 'DEPRECATED: 하위 호환성을 위해 유지. transaction_*_enabled 사용 권장';
COMMENT ON COLUMN house.notification_settings.transaction_added_enabled IS '다른 멤버 거래 추가 알림 활성화 여부';
COMMENT ON COLUMN house.notification_settings.transaction_updated_enabled IS '다른 멤버 거래 수정 알림 활성화 여부';
COMMENT ON COLUMN house.notification_settings.transaction_deleted_enabled IS '다른 멤버 거래 삭제 알림 활성화 여부';
COMMENT ON COLUMN house.notification_settings.auto_collect_suggested_enabled IS '자동수집 거래 제안 알림 활성화 여부 (suggest 모드)';
COMMENT ON COLUMN house.notification_settings.auto_collect_saved_enabled IS '자동수집 거래 자동저장 알림 활성화 여부 (auto 모드)';

-- 2. push_notifications 테이블 type CHECK 제약 조건 수정
ALTER TABLE house.push_notifications DROP CONSTRAINT IF EXISTS push_notifications_type_check;

ALTER TABLE house.push_notifications
ADD CONSTRAINT push_notifications_type_check
CHECK (type IN (
    'budget_warning',
    'budget_exceeded',
    'shared_ledger_change',           -- deprecated (하위 호환성)
    'transaction_added',              -- 신규
    'transaction_updated',            -- 신규
    'transaction_deleted',            -- 신규
    'auto_collect_suggested',         -- 신규
    'auto_collect_saved',             -- 신규
    'invite_received',
    'invite_accepted'
));

COMMENT ON CONSTRAINT push_notifications_type_check ON house.push_notifications IS '알림 타입 제약 조건 (세분화됨)';

-- 3. 신규 사용자 기본 설정 트리거 함수 업데이트
CREATE OR REPLACE FUNCTION house.handle_new_user_notification_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO house.notification_settings (
        user_id,
        budget_warning_enabled,
        budget_exceeded_enabled,
        shared_ledger_change_enabled,
        transaction_added_enabled,
        transaction_updated_enabled,
        transaction_deleted_enabled,
        auto_collect_suggested_enabled,
        auto_collect_saved_enabled,
        invite_received_enabled,
        invite_accepted_enabled
    )
    VALUES (
        NEW.id,
        TRUE,  -- budget_warning_enabled
        TRUE,  -- budget_exceeded_enabled
        TRUE,  -- shared_ledger_change_enabled (deprecated)
        TRUE,  -- transaction_added_enabled
        TRUE,  -- transaction_updated_enabled
        TRUE,  -- transaction_deleted_enabled
        TRUE,  -- auto_collect_suggested_enabled
        TRUE,  -- auto_collect_saved_enabled
        TRUE,  -- invite_received_enabled
        TRUE   -- invite_accepted_enabled
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION house.handle_new_user_notification_settings() IS '신규 사용자 생성 시 기본 알림 설정 자동 생성 (세분화 반영)';

-- 4. 검증 쿼리 (마이그레이션 완료 후 실행 권장)
-- SELECT column_name, data_type, column_default, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'house'
--   AND table_name = 'notification_settings'
-- ORDER BY ordinal_position;
