-- 038_fix_pending_transactions_rls.sql
-- pending_transactions RLS 정책 수정: 본인 거래만 조회 가능
-- 
-- 문제: 현재 정책은 ledger_id만 체크하여 같은 가계부 멤버가 서로의 자동수집 거래를 볼 수 있음
-- 해결: user_id로 본인 거래만 조회하도록 제한
--
-- 영향: 자동수집 기능은 개인별 결제수단에만 적용되므로, 
--       공유 가계부에서도 각자의 자동수집 거래만 보이도록 변경

-- ============================================
-- 1. SELECT 정책 수정 (본인 거래만 조회)
-- ============================================

DROP POLICY IF EXISTS "pending_transactions_select_policy" ON house.pending_transactions;

CREATE POLICY "pending_transactions_select_policy"
    ON house.pending_transactions FOR SELECT
    USING (
        user_id = auth.uid()
    );

COMMENT ON POLICY "pending_transactions_select_policy" ON house.pending_transactions 
IS '본인이 생성한 대기 거래만 조회 가능 (자동수집은 개인별 기능)';

-- ============================================
-- 2. UPDATE 정책 수정 (본인 거래만 수정)
-- ============================================

DROP POLICY IF EXISTS "pending_transactions_update_policy" ON house.pending_transactions;

CREATE POLICY "pending_transactions_update_policy"
    ON house.pending_transactions FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

COMMENT ON POLICY "pending_transactions_update_policy" ON house.pending_transactions 
IS '본인이 생성한 대기 거래만 수정 가능';

-- ============================================
-- 3. DELETE 정책 수정 (본인 거래만 삭제)
-- ============================================

DROP POLICY IF EXISTS "pending_transactions_delete_policy" ON house.pending_transactions;

CREATE POLICY "pending_transactions_delete_policy"
    ON house.pending_transactions FOR DELETE
    USING (user_id = auth.uid());

COMMENT ON POLICY "pending_transactions_delete_policy" ON house.pending_transactions 
IS '본인이 생성한 대기 거래만 삭제 가능';

-- ============================================
-- 4. 검증 쿼리 (마이그레이션 후 확인용)
-- ============================================

-- 정책 확인
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies 
-- WHERE schemaname = 'house' AND tablename = 'pending_transactions'
-- ORDER BY policyname;
