-- Migration: Add missing FK indexes and consolidate RLS policies
-- This addresses performance and security issues identified in code review

-- ============================================
-- 1. ADD MISSING FOREIGN KEY INDEXES
-- ============================================

-- ledger_invites.inviter_user_id (FK to profiles)
CREATE INDEX IF NOT EXISTS idx_ledger_invites_inviter_user_id 
ON house.ledger_invites(inviter_user_id);

-- ledger_invites.ledger_id (FK to ledgers)
CREATE INDEX IF NOT EXISTS idx_ledger_invites_ledger_id 
ON house.ledger_invites(ledger_id);

-- ledgers.owner_id (FK to profiles)
CREATE INDEX IF NOT EXISTS idx_ledgers_owner_id 
ON house.ledgers(owner_id);

-- recurring_templates FK columns
CREATE INDEX IF NOT EXISTS idx_recurring_templates_ledger_id 
ON house.recurring_templates(ledger_id);

CREATE INDEX IF NOT EXISTS idx_recurring_templates_category_id 
ON house.recurring_templates(category_id);

CREATE INDEX IF NOT EXISTS idx_recurring_templates_payment_method_id 
ON house.recurring_templates(payment_method_id);

CREATE INDEX IF NOT EXISTS idx_recurring_templates_user_id 
ON house.recurring_templates(user_id);

-- asset_goals FK columns
CREATE INDEX IF NOT EXISTS idx_asset_goals_ledger_id 
ON house.asset_goals(ledger_id);

CREATE INDEX IF NOT EXISTS idx_asset_goals_created_by 
ON house.asset_goals(created_by);

-- ============================================
-- 2. CONSOLIDATE MULTIPLE PERMISSIVE DELETE POLICIES ON ledger_invites
-- ============================================

-- Drop existing DELETE policies
DROP POLICY IF EXISTS "Users can delete their own pending invites" ON house.ledger_invites;
DROP POLICY IF EXISTS "Invitees can delete their pending invites" ON house.ledger_invites;

-- Create single consolidated DELETE policy
CREATE POLICY "Users can delete pending invites they created or received"
ON house.ledger_invites
FOR DELETE
USING (
  status = 'pending'
  AND (
    inviter_user_id = auth.uid()
    OR invitee_email = (SELECT email FROM auth.users WHERE id = auth.uid())
  )
);

-- ============================================
-- 3. ADD MISSING RLS POLICIES
-- ============================================

-- push_notifications DELETE policy
DROP POLICY IF EXISTS "Users can delete own notifications" ON house.push_notifications;
CREATE POLICY "Users can delete own notifications"
ON house.push_notifications
FOR DELETE
USING (user_id = auth.uid());

-- ============================================
-- 4. FIX OVERLY PERMISSIVE POLICIES
-- ============================================

-- recurring_templates: Only creator (user_id) can UPDATE/DELETE
DROP POLICY IF EXISTS "Members can update recurring templates" ON house.recurring_templates;
DROP POLICY IF EXISTS "Members can delete recurring templates" ON house.recurring_templates;

CREATE POLICY "Creator can update recurring templates"
ON house.recurring_templates
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Creator can delete recurring templates"
ON house.recurring_templates
FOR DELETE
USING (user_id = auth.uid());

-- asset_goals: Only creator can UPDATE/DELETE
DROP POLICY IF EXISTS "Members can update asset goals" ON house.asset_goals;
DROP POLICY IF EXISTS "Members can delete asset goals" ON house.asset_goals;

CREATE POLICY "Creator can update asset goals"
ON house.asset_goals
FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

CREATE POLICY "Creator can delete asset goals"
ON house.asset_goals
FOR DELETE
USING (created_by = auth.uid());
