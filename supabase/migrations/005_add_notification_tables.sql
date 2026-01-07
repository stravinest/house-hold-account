-- 푸시 알림 기능을 위한 테이블 추가
-- 실행일: 2026-01-06

-- FCM 토큰 테이블
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type TEXT NOT NULL CHECK (device_type IN ('android', 'ios', 'web')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- 알림 설정 테이블
CREATE TABLE IF NOT EXISTS notification_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    budget_warning_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    budget_exceeded_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    shared_ledger_change_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    invite_received_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    invite_accepted_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 알림 기록 테이블 (선택 사항 - 알림 히스토리 저장용)
CREATE TABLE IF NOT EXISTS push_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (
        type IN (
            'budget_warning',
            'budget_exceeded',
            'shared_ledger_change',
            'invite_received',
            'invite_accepted'
        )
    ),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_settings_user_id ON notification_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_push_notifications_user_id ON push_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_push_notifications_is_read ON push_notifications(is_read);

-- RLS (Row Level Security) 정책 활성화
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;

-- fcm_tokens 테이블 RLS 정책
CREATE POLICY 'Users can view their own FCM tokens'
    ON fcm_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY 'Users can insert their own FCM tokens'
    ON fcm_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY 'Users can update their own FCM tokens'
    ON fcm_tokens FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY 'Users can delete their own FCM tokens'
    ON fcm_tokens FOR DELETE
    USING (auth.uid() = user_id);

-- notification_settings 테이블 RLS 정책
CREATE POLICY 'Users can view their own notification settings'
    ON notification_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY 'Users can insert their own notification settings'
    ON notification_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY 'Users can update their own notification settings'
    ON notification_settings FOR UPDATE
    USING (auth.uid() = user_id);

-- push_notifications 테이블 RLS 정책
CREATE POLICY 'Users can view their own push notifications'
    ON push_notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY 'Users can update their own push notifications'
    ON push_notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- 트리거: 회원가입 시 기본 알림 설정 자동 생성
CREATE OR REPLACE FUNCTION handle_new_user_notification_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notification_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기존 트리거가 있으면 삭제 후 재생성
DROP TRIGGER IF EXISTS on_auth_user_created_notification_settings ON auth.users;

CREATE TRIGGER on_auth_user_created_notification_settings
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user_notification_settings();

-- 기존 사용자들에 대해 기본 알림 설정 생성 (마이그레이션 실행 시)
INSERT INTO notification_settings (user_id)
SELECT id FROM profiles
WHERE id NOT IN (SELECT user_id FROM notification_settings)
ON CONFLICT (user_id) DO NOTHING;
