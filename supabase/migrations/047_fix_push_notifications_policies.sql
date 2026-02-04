-- push_notifications 테이블 RLS 및 CHECK 제약 수정
-- 문제 1: INSERT 정책 누락으로 403 에러 발생
-- 문제 2: auto_collect_saved, auto_collect_suggested 타입 누락
-- 실행일: 2026-02-04

-- 1. INSERT 정책 추가
CREATE POLICY "Users can insert their own push notifications"
    ON push_notifications FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 2. type CHECK 제약 조건 제거 후 재생성
ALTER TABLE push_notifications DROP CONSTRAINT IF EXISTS push_notifications_type_check;

ALTER TABLE push_notifications ADD CONSTRAINT push_notifications_type_check
    CHECK (
        type IN (
            'budget_warning',
            'budget_exceeded',
            'shared_ledger_change',
            'invite_received',
            'invite_accepted',
            'auto_collect_saved',
            'auto_collect_suggested'
        )
    );
