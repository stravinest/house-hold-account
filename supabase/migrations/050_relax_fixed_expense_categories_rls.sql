-- fixed_expense_categories RLS 정책 완화
-- 기존: owner/admin만 INSERT/UPDATE/DELETE 가능
-- 변경: 모든 멤버가 INSERT/UPDATE/DELETE 가능 (transactions 정책과 동일)
-- 원인: member role 사용자가 고정비 카테고리를 추가할 수 없는 버그

-- INSERT 정책 변경
DROP POLICY IF EXISTS "fec_insert_policy" ON house.fixed_expense_categories;
CREATE POLICY "fec_insert_policy"
    ON house.fixed_expense_categories FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
        )
    );

-- UPDATE 정책 변경
DROP POLICY IF EXISTS "fec_update_policy" ON house.fixed_expense_categories;
CREATE POLICY "fec_update_policy"
    ON house.fixed_expense_categories FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
        )
    );

-- DELETE 정책 변경
DROP POLICY IF EXISTS "fec_delete_policy" ON house.fixed_expense_categories;
CREATE POLICY "fec_delete_policy"
    ON house.fixed_expense_categories FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
        )
    );

-- fixed_expense_settings도 동일하게 완화
DROP POLICY IF EXISTS "fes_insert_policy" ON house.fixed_expense_settings;
CREATE POLICY "fes_insert_policy"
    ON house.fixed_expense_settings FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "fes_update_policy" ON house.fixed_expense_settings;
CREATE POLICY "fes_update_policy"
    ON house.fixed_expense_settings FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members
            WHERE user_id = auth.uid()
        )
    );
