-- RLS 정책 보안 개선
-- 문제: push_notifications과 fixed_expense_settings DELETE 정책 누락
--       ledger_invites와 ledger_members 정책명 충돌
-- 해결: 누락된 정책 추가 및 정책 분리
-- 실행일: 2026-01-18

-- 1. push_notifications DELETE 정책 추가
CREATE POLICY 'Users can delete their own push notifications'
    ON push_notifications FOR DELETE
    USING (auth.uid() = user_id);

-- 2. fixed_expense_settings DELETE 정책 추가
CREATE POLICY 'fes_delete_policy'
    ON fixed_expense_settings FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- 3. ledger_members INSERT 정책 이름 변경 (011 마이그레이션과 충돌 방지)
-- 기존 정책 삭제
DROP POLICY IF EXISTS '소유자/관리자/초대받은자는 멤버를 추가할 수 있음' ON ledger_members;

-- 새로운 정책 생성: 초대받은 사용자가 멤버로 등록
CREATE POLICY '초대받은자는 자신을 멤버로 추가할 수 있음'
    ON ledger_members FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM ledger_invites li
            JOIN profiles p ON p.email = li.invitee_email
            WHERE li.ledger_id = ledger_members.ledger_id
            AND p.id = auth.uid()
            AND li.status = 'pending'
            AND li.expires_at > NOW()
        )
    );

-- 4. ledger_invites DELETE 정책명 정리
-- 기존 정책 삭제 (025 마이그레이션과 중복 방지)
DROP POLICY IF EXISTS '소유자/초대자/초대받은자는 초대를 삭제할 수 있음' ON ledger_invites;

-- 새로운 정책 생성: 초대 삭제 권한
CREATE POLICY '초대를 삭제할 수 있음'
    ON ledger_invites FOR DELETE
    USING (
        inviter_user_id = auth.uid()
        OR ledger_id IN (
            SELECT id FROM ledgers WHERE owner_id = auth.uid()
        )
        OR invitee_email = (SELECT email FROM profiles WHERE id = auth.uid())
    );
