-- 고정비 설정을 유저별 독립 설정으로 변경
-- 기존: ledger_id당 1개 레코드 (공유 가계부 전체 적용)
-- 변경: (ledger_id, user_id)당 1개 레코드 (유저별 독립)

SET search_path TO house, public;

-- 1. user_id 컬럼 추가
ALTER TABLE house.fixed_expense_settings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- 2. 기존 데이터를 모든 멤버에게 복제
INSERT INTO house.fixed_expense_settings (ledger_id, user_id, include_in_expense, created_at, updated_at)
SELECT fes.ledger_id, lm.user_id, fes.include_in_expense, fes.created_at, fes.updated_at
FROM house.fixed_expense_settings fes
JOIN house.ledger_members lm ON lm.ledger_id = fes.ledger_id
WHERE fes.user_id IS NULL
ON CONFLICT DO NOTHING;

-- 3. 기존 user_id=null 레코드 삭제
DELETE FROM house.fixed_expense_settings WHERE user_id IS NULL;

-- 4. NOT NULL 제약 추가
ALTER TABLE house.fixed_expense_settings ALTER COLUMN user_id SET NOT NULL;

-- 5. UNIQUE 제약 변경: (ledger_id) -> (ledger_id, user_id)
ALTER TABLE house.fixed_expense_settings DROP CONSTRAINT IF EXISTS fixed_expense_settings_ledger_id_key;
ALTER TABLE house.fixed_expense_settings ADD CONSTRAINT fixed_expense_settings_ledger_id_user_id_key UNIQUE(ledger_id, user_id);

-- 6. 기존 RLS 정책 삭제
DROP POLICY IF EXISTS "fes_select_policy" ON house.fixed_expense_settings;
DROP POLICY IF EXISTS "fes_insert_policy" ON house.fixed_expense_settings;
DROP POLICY IF EXISTS "fes_update_policy" ON house.fixed_expense_settings;

-- 7. 새 RLS 정책: 본인 설정만 조회/수정
CREATE POLICY "fes_select_own"
    ON house.fixed_expense_settings FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "fes_insert_own"
    ON house.fixed_expense_settings FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "fes_update_own"
    ON house.fixed_expense_settings FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "fes_delete_own"
    ON house.fixed_expense_settings FOR DELETE
    USING (user_id = auth.uid());

-- 8. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_fixed_expense_settings_user_id ON house.fixed_expense_settings(user_id);

-- 9. 새 멤버 참가 시 자동으로 고정비 설정 생성하는 트리거
CREATE OR REPLACE FUNCTION house.create_fixed_expense_settings_for_member()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO house.fixed_expense_settings (ledger_id, user_id, include_in_expense)
    VALUES (NEW.ledger_id, NEW.user_id, FALSE)
    ON CONFLICT (ledger_id, user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_create_fixed_expense_settings_for_member ON house.ledger_members;
CREATE TRIGGER trigger_create_fixed_expense_settings_for_member
    AFTER INSERT ON house.ledger_members
    FOR EACH ROW
    EXECUTE FUNCTION house.create_fixed_expense_settings_for_member();

-- 10. 멤버 탈퇴 시 고정비 설정 자동 삭제 트리거
CREATE OR REPLACE FUNCTION house.delete_fixed_expense_settings_for_member()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM house.fixed_expense_settings
    WHERE ledger_id = OLD.ledger_id AND user_id = OLD.user_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_delete_fixed_expense_settings_for_member ON house.ledger_members;
CREATE TRIGGER trigger_delete_fixed_expense_settings_for_member
    AFTER DELETE ON house.ledger_members
    FOR EACH ROW
    EXECUTE FUNCTION house.delete_fixed_expense_settings_for_member();
