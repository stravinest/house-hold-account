-- RLS 정책 세분화된 권한 관리
-- 문제: recurring_templates, asset_goals에서 모든 멤버가 모든 데이터 수정/삭제 가능
-- 해결: 소유권 기반 접근제어 추가
-- 실행일: 2026-01-18

-- 1. recurring_templates 정책 세분화
-- 기존 UPDATE 정책 삭제
DROP POLICY IF EXISTS '멤버는 반복 템플릿을 수정할 수 있음' ON recurring_templates;

-- 새로운 UPDATE 정책: 작성자 또는 owner/admin만 수정 가능
CREATE POLICY '사용자는 자신의 반복 템플릿을 수정할 수 있음'
    ON recurring_templates FOR UPDATE
    USING (
        user_id = auth.uid()
        OR ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- 기존 DELETE 정책 삭제
DROP POLICY IF EXISTS '멤버는 반복 템플릿을 삭제할 수 있음' ON recurring_templates;

-- 새로운 DELETE 정책: 작성자 또는 owner/admin만 삭제 가능
CREATE POLICY '사용자는 자신의 반복 템플릿을 삭제할 수 있음'
    ON recurring_templates FOR DELETE
    USING (
        user_id = auth.uid()
        OR ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- 2. asset_goals 정책 세분화
-- 기존 UPDATE 정책 삭제
DROP POLICY IF EXISTS 'Members can update goals' ON asset_goals;

-- 새로운 UPDATE 정책: 작성자 또는 owner/admin만 수정 가능
CREATE POLICY 'Members can update their own goals' ON asset_goals
    FOR UPDATE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM ledger_members
            WHERE ledger_members.ledger_id = asset_goals.ledger_id
            AND ledger_members.user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

-- 기존 DELETE 정책 삭제
DROP POLICY IF EXISTS 'Members can delete goals' ON asset_goals;

-- 새로운 DELETE 정책: 작성자 또는 owner/admin만 삭제 가능
CREATE POLICY 'Members can delete their own goals' ON asset_goals
    FOR DELETE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM ledger_members
            WHERE ledger_members.ledger_id = asset_goals.ledger_id
            AND ledger_members.user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

-- 3. ledger_invites SELECT 정책 개선 (선택사항)
-- 초대 기록이 수락된 후에도 계속 보여지는 문제 해결
-- 주의: 이 정책은 사용 사례를 먼저 검토한 후 적용할 것
-- DROP POLICY IF EXISTS '초대받은 사용자는 자신의 초대를 조회할 수 있음' ON ledger_invites;
-- 
-- CREATE POLICY 'Users can view their own pending invites'
--     ON ledger_invites FOR SELECT
--     USING (
--         (invitee_email = (SELECT email FROM profiles WHERE id = auth.uid()) AND status = 'pending')
--         OR inviter_user_id = auth.uid()
--         OR ledger_id IN (
--             SELECT ledger_id FROM ledger_members
--             WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
--         )
--     );
