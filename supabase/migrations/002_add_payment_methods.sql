-- 지출수단(결제수단) 기능 추가
-- 2026-01-05

-- payment_methods 테이블 생성
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT DEFAULT '',
    color TEXT DEFAULT '#6750A4',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ledger_id, name)
);

-- transactions 테이블에 payment_method_id 컬럼 추가
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES payment_methods(id) ON DELETE SET NULL;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_payment_methods_ledger_id ON payment_methods(ledger_id);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_method_id ON transactions(payment_method_id);

-- RLS 활성화
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

-- payment_methods 정책
CREATE POLICY "멤버는 가계부의 결제수단을 조회할 수 있음"
    ON payment_methods FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "소유자/관리자는 결제수단을 생성할 수 있음"
    ON payment_methods FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자/관리자는 결제수단을 수정할 수 있음"
    ON payment_methods FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "소유자/관리자는 결제수단을 삭제할 수 있음"
    ON payment_methods FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- 트리거: 가계부 생성 시 기본 결제수단 추가
CREATE OR REPLACE FUNCTION handle_new_ledger_payment_methods()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO payment_methods (ledger_id, name, icon, color, is_default, sort_order) VALUES
        (NEW.id, '현금', '', '#4CAF50', TRUE, 1),
        (NEW.id, '카드', '', '#2196F3', FALSE, 2);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ledger_created_payment_methods ON ledgers;
CREATE TRIGGER on_ledger_created_payment_methods
    AFTER INSERT ON ledgers
    FOR EACH ROW EXECUTE FUNCTION handle_new_ledger_payment_methods();

-- Realtime 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE payment_methods;
