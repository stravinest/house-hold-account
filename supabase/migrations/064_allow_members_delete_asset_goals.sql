-- 가계부 멤버라면 누구나 자산 목표 삭제 가능하도록 RLS 정책 수정
-- 기존: created_by = auth.uid() (본인만 삭제)
-- 변경: 가계부 멤버면 삭제 가능

DROP POLICY IF EXISTS "Creator can delete asset goals" ON house.asset_goals;
CREATE POLICY "Members can delete asset goals" ON house.asset_goals
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM house.ledger_members
    WHERE ledger_members.ledger_id = asset_goals.ledger_id
      AND ledger_members.user_id = (SELECT auth.uid())
  )
);
