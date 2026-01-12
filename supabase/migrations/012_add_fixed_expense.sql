-- 고정비(Fixed Expense) 기능 추가
-- 2026-01-12

-- 1. fixed_expense_categories 테이블 (고정비 카테고리)
CREATE TABLE IF NOT EXISTS fixed_expense_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT DEFAULT '',
    color TEXT DEFAULT '#6750A4',
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ledger_id, name)
);

-- 2. fixed_expense_settings 테이블 (고정비 전역 설정)
CREATE TABLE IF NOT EXISTS fixed_expense_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    include_in_expense BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ledger_id)
);

-- 3. transactions 테이블 확장
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS is_fixed_expense BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS fixed_expense_category_id UUID REFERENCES fixed_expense_categories(id) ON DELETE SET NULL;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_fixed_expense_categories_ledger_id ON fixed_expense_categories(ledger_id);
CREATE INDEX IF NOT EXISTS idx_transactions_is_fixed_expense ON transactions(is_fixed_expense);
CREATE INDEX IF NOT EXISTS idx_transactions_fixed_expense_category_id ON transactions(fixed_expense_category_id);

-- RLS 활성화
ALTER TABLE fixed_expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_expense_settings ENABLE ROW LEVEL SECURITY;

-- fixed_expense_categories 정책
CREATE POLICY "fec_select_policy"
    ON fixed_expense_categories FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "fec_insert_policy"
    ON fixed_expense_categories FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "fec_update_policy"
    ON fixed_expense_categories FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "fec_delete_policy"
    ON fixed_expense_categories FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- fixed_expense_settings 정책
CREATE POLICY "fes_select_policy"
    ON fixed_expense_settings FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "fes_insert_policy"
    ON fixed_expense_settings FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "fes_update_policy"
    ON fixed_expense_settings FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- 트리거: 가계부 생성 시 기본 고정비 설정 및 카테고리 추가
CREATE OR REPLACE FUNCTION handle_new_ledger_fixed_expense()
RETURNS TRIGGER AS $$
BEGIN
    -- 기본 설정 생성
    INSERT INTO fixed_expense_settings (ledger_id, include_in_expense)
    VALUES (NEW.id, FALSE);

    -- 기본 고정비 카테고리 생성
    INSERT INTO fixed_expense_categories (ledger_id, name, icon, color, sort_order) VALUES
        (NEW.id, '월세/관리비', '', '#FF6B6B', 1),
        (NEW.id, '보험료', '', '#4ECDC4', 2),
        (NEW.id, '통신비', '', '#45B7D1', 3),
        (NEW.id, '구독료', '', '#96CEB4', 4),
        (NEW.id, '대출 상환', '', '#FFEAA7', 5);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ledger_created_fixed_expense ON ledgers;
CREATE TRIGGER on_ledger_created_fixed_expense
    AFTER INSERT ON ledgers
    FOR EACH ROW EXECUTE FUNCTION handle_new_ledger_fixed_expense();

-- 기존 가계부에 대한 기본 설정 및 카테고리 추가 (1회성)
INSERT INTO fixed_expense_settings (ledger_id, include_in_expense)
SELECT id, FALSE FROM ledgers
WHERE id NOT IN (SELECT ledger_id FROM fixed_expense_settings)
ON CONFLICT (ledger_id) DO NOTHING;

INSERT INTO fixed_expense_categories (ledger_id, name, icon, color, sort_order)
SELECT l.id, fc.name, fc.icon, fc.color, fc.sort_order
FROM ledgers l
CROSS JOIN (
    VALUES
        ('월세/관리비', '', '#FF6B6B', 1),
        ('보험료', '', '#4ECDC4', 2),
        ('통신비', '', '#45B7D1', 3),
        ('구독료', '', '#96CEB4', 4),
        ('대출 상환', '', '#FFEAA7', 5)
) AS fc(name, icon, color, sort_order)
WHERE l.id NOT IN (
    SELECT DISTINCT ledger_id FROM fixed_expense_categories
)
ON CONFLICT (ledger_id, name) DO NOTHING;

-- Realtime 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE fixed_expense_categories;
ALTER PUBLICATION supabase_realtime ADD TABLE fixed_expense_settings;
