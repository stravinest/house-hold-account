-- ============================================
-- 1. 중복 인덱스 삭제
-- ============================================
DROP INDEX IF EXISTS house.idx_asset_goals_ledger_id;

-- ============================================
-- 2. 중복 RLS 정책 삭제 (Creator 정책만 유지)
-- ============================================
DROP POLICY IF EXISTS "asset_goals_update" ON house.asset_goals;
DROP POLICY IF EXISTS "asset_goals_delete" ON house.asset_goals;
DROP POLICY IF EXISTS "recurring_templates_update" ON house.recurring_templates;
DROP POLICY IF EXISTS "recurring_templates_delete" ON house.recurring_templates;

-- ============================================
-- 3. RLS 성능 개선: auth.uid() -> (select auth.uid())
-- ============================================

-- 3-1. profiles_select_same_ledger_members
DROP POLICY IF EXISTS "profiles_select_same_ledger_members" ON house.profiles;
CREATE POLICY "profiles_select_same_ledger_members" ON house.profiles
FOR SELECT USING (
  id = (select auth.uid())
  OR id IN (
    SELECT DISTINCT lm2.user_id
    FROM house.ledger_members lm1
    JOIN house.ledger_members lm2 ON lm1.ledger_id = lm2.ledger_id
    WHERE lm1.user_id = (select auth.uid())
  )
);

-- 3-2. ledger_invites_delete_unified
DROP POLICY IF EXISTS "ledger_invites_delete_unified" ON house.ledger_invites;
CREATE POLICY "ledger_invites_delete_unified" ON house.ledger_invites
FOR DELETE USING (
  inviter_user_id = (select auth.uid())
  OR ledger_id IN (SELECT id FROM house.ledgers WHERE owner_id = (select auth.uid()))
  OR invitee_email = house.get_user_email((select auth.uid()))
);

-- 3-3. Creator can update recurring templates
DROP POLICY IF EXISTS "Creator can update recurring templates" ON house.recurring_templates;
CREATE POLICY "Creator can update recurring templates" ON house.recurring_templates
FOR UPDATE USING (user_id = (select auth.uid()));

-- 3-4. Creator can delete recurring templates
DROP POLICY IF EXISTS "Creator can delete recurring templates" ON house.recurring_templates;
CREATE POLICY "Creator can delete recurring templates" ON house.recurring_templates
FOR DELETE USING (user_id = (select auth.uid()));

-- 3-5. Creator can update asset goals
DROP POLICY IF EXISTS "Creator can update asset goals" ON house.asset_goals;
CREATE POLICY "Creator can update asset goals" ON house.asset_goals
FOR UPDATE USING (created_by = (select auth.uid()));

-- 3-6. Creator can delete asset goals
DROP POLICY IF EXISTS "Creator can delete asset goals" ON house.asset_goals;
CREATE POLICY "Creator can delete asset goals" ON house.asset_goals
FOR DELETE USING (created_by = (select auth.uid()));

-- 3-7. Users can delete own notifications
DROP POLICY IF EXISTS "Users can delete own notifications" ON house.push_notifications;
CREATE POLICY "Users can delete own notifications" ON house.push_notifications
FOR DELETE USING (user_id = (select auth.uid()));
