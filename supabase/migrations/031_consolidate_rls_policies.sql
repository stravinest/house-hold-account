-- Migration: 031_consolidate_rls_policies.sql
-- 1. profiles SELECT: 같은 가계부 멤버만 조회 가능하도록 변경
-- 2. ledger_invites DELETE: 3개 정책을 1개로 통합

-- ============================================
-- 1. profiles SELECT RLS 변경
-- ============================================
DROP POLICY IF EXISTS "profiles_select" ON house.profiles;
DROP POLICY IF EXISTS "사용자는 모든 프로필을 조회할 수 있음" ON house.profiles;

CREATE POLICY "profiles_select_same_ledger_members" ON house.profiles
FOR SELECT USING (
  -- 자기 자신
  id = auth.uid()
  OR
  -- 같은 가계부의 멤버
  id IN (
    SELECT DISTINCT lm2.user_id
    FROM house.ledger_members lm1
    JOIN house.ledger_members lm2 ON lm1.ledger_id = lm2.ledger_id
    WHERE lm1.user_id = auth.uid()
  )
);

-- ============================================
-- 2. ledger_invites DELETE 정책 통합
-- ============================================
DROP POLICY IF EXISTS "Users can delete pending invites they created or received" ON house.ledger_invites;
DROP POLICY IF EXISTS "invites_owner_inviter_invitee_delete" ON house.ledger_invites;
DROP POLICY IF EXISTS "ledger_invites_delete" ON house.ledger_invites;
DROP POLICY IF EXISTS "소유자/관리자/초대자는 초대를 삭제할 수 있음" ON house.ledger_invites;
DROP POLICY IF EXISTS "소유자/초대자/초대받은자는 초대를 삭제할 수 있음" ON house.ledger_invites;
DROP POLICY IF EXISTS "초대를 삭제할 수 있음" ON house.ledger_invites;

CREATE POLICY "ledger_invites_delete_unified" ON house.ledger_invites
FOR DELETE USING (
  -- 초대한 사람
  inviter_user_id = auth.uid()
  OR
  -- 가계부 소유자
  ledger_id IN (SELECT id FROM house.ledgers WHERE owner_id = auth.uid())
  OR
  -- 초대받은 사람
  invitee_email = house.get_user_email(auth.uid())
);
