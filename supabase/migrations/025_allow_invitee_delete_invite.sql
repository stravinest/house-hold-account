-- 초대받은 사람도 자신의 초대 기록을 삭제할 수 있도록 RLS 정책 수정
-- 탈퇴 시 초대 기록 삭제를 위해 필요

-- 기존 정책 삭제
DROP POLICY IF EXISTS "소유자/관리자/초대자는 초대를 삭제할 수 있음" ON house.ledger_invites;

-- 새 정책 생성 (초대받은 사람도 자신의 초대 기록 삭제 가능)
CREATE POLICY "소유자/초대자/초대받은자는 초대를 삭제할 수 있음"
    ON house.ledger_invites FOR DELETE
    USING (
        inviter_user_id = auth.uid()
        OR ledger_id IN (
            SELECT id FROM house.ledgers WHERE owner_id = auth.uid()
        )
        OR invitee_email = (SELECT email FROM house.profiles WHERE id = auth.uid())
    );
