-- 반복 거래 템플릿 테이블 및 자동 생성 시스템
-- 매일 00:00에 pg_cron이 실행되어 오늘까지의 반복 거래를 자동 생성

-- pg_cron 확장 활성화
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;

-- 반복 거래 템플릿 테이블
CREATE TABLE IF NOT EXISTS recurring_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    payment_method_id UUID REFERENCES payment_methods(id) ON DELETE SET NULL,

    -- 거래 정보
    amount INT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'saving')),
    title TEXT,
    memo TEXT,

    -- 반복 설정
    recurring_type TEXT NOT NULL CHECK (recurring_type IN ('daily', 'monthly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE, -- NULL이면 무기한 반복
    recurring_day INT, -- 매월/매년 반복 시 실행할 날짜 (1-31)

    -- 고정비 설정
    is_fixed_expense BOOLEAN NOT NULL DEFAULT FALSE,
    fixed_expense_category_id UUID REFERENCES fixed_expense_categories(id) ON DELETE SET NULL,

    -- 마지막 생성 날짜 (이 날짜까지 거래가 생성됨)
    last_generated_date DATE,

    -- 활성화 여부
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_recurring_templates_ledger_id ON recurring_templates(ledger_id);
CREATE INDEX IF NOT EXISTS idx_recurring_templates_user_id ON recurring_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_templates_is_active ON recurring_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_recurring_templates_end_date ON recurring_templates(end_date);

-- RLS 활성화
ALTER TABLE recurring_templates ENABLE ROW LEVEL SECURITY;

-- recurring_templates 정책
CREATE POLICY "멤버는 반복 템플릿을 조회할 수 있음"
    ON recurring_templates FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "멤버는 반복 템플릿을 생성할 수 있음"
    ON recurring_templates FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "멤버는 반복 템플릿을 수정할 수 있음"
    ON recurring_templates FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "멤버는 반복 템플릿을 삭제할 수 있음"
    ON recurring_templates FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );

-- 다음 반복 날짜 계산 함수
CREATE OR REPLACE FUNCTION calculate_next_recurring_date(
    p_current_date DATE,
    p_recurring_type TEXT,
    p_recurring_day INT
)
RETURNS DATE AS $$
DECLARE
    v_next_date DATE;
    v_year INT;
    v_month INT;
    v_day INT;
    v_last_day INT;
BEGIN
    CASE p_recurring_type
        WHEN 'daily' THEN
            v_next_date := p_current_date + INTERVAL '1 day';

        WHEN 'monthly' THEN
            v_year := EXTRACT(YEAR FROM p_current_date);
            v_month := EXTRACT(MONTH FROM p_current_date) + 1;

            IF v_month > 12 THEN
                v_month := 1;
                v_year := v_year + 1;
            END IF;

            -- 해당 월의 마지막 날 계산
            v_last_day := EXTRACT(DAY FROM (DATE_TRUNC('month', MAKE_DATE(v_year, v_month, 1)) + INTERVAL '1 month - 1 day'));
            v_day := LEAST(p_recurring_day, v_last_day);

            v_next_date := MAKE_DATE(v_year, v_month, v_day);

        WHEN 'yearly' THEN
            v_year := EXTRACT(YEAR FROM p_current_date) + 1;
            v_month := EXTRACT(MONTH FROM p_current_date);
            v_day := EXTRACT(DAY FROM p_current_date);

            -- 윤년 처리 (2월 29일 -> 2월 28일)
            IF v_month = 2 AND v_day = 29 THEN
                v_last_day := EXTRACT(DAY FROM (DATE_TRUNC('month', MAKE_DATE(v_year, v_month, 1)) + INTERVAL '1 month - 1 day'));
                v_day := LEAST(v_day, v_last_day);
            END IF;

            v_next_date := MAKE_DATE(v_year, v_month, v_day);

        ELSE
            v_next_date := NULL;
    END CASE;

    RETURN v_next_date;
END;
$$ LANGUAGE plpgsql;

-- 반복 거래 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_recurring_transactions()
RETURNS TABLE(
    template_id UUID,
    transactions_created INT,
    error_message TEXT
) AS $$
DECLARE
    v_template RECORD;
    v_current_date DATE;
    v_target_date DATE;
    v_transactions_count INT;
    v_today DATE := CURRENT_DATE;
BEGIN
    -- 활성화된 모든 템플릿 순회
    FOR v_template IN
        SELECT * FROM recurring_templates
        WHERE is_active = TRUE
        AND (end_date IS NULL OR end_date >= v_today)
    LOOP
        BEGIN
            v_transactions_count := 0;

            -- 시작 날짜 결정
            IF v_template.last_generated_date IS NULL THEN
                v_current_date := v_template.start_date;
            ELSE
                v_current_date := calculate_next_recurring_date(
                    v_template.last_generated_date,
                    v_template.recurring_type,
                    v_template.recurring_day
                );
            END IF;

            -- 오늘까지의 거래 생성
            WHILE v_current_date <= v_today AND
                  (v_template.end_date IS NULL OR v_current_date <= v_template.end_date)
            LOOP
                -- 거래 생성
                INSERT INTO transactions (
                    ledger_id,
                    category_id,
                    user_id,
                    payment_method_id,
                    amount,
                    type,
                    date,
                    title,
                    memo,
                    is_recurring,
                    recurring_type,
                    recurring_end_date,
                    is_fixed_expense,
                    fixed_expense_category_id
                ) VALUES (
                    v_template.ledger_id,
                    v_template.category_id,
                    v_template.user_id,
                    v_template.payment_method_id,
                    v_template.amount,
                    v_template.type,
                    v_current_date,
                    v_template.title,
                    v_template.memo,
                    TRUE,
                    v_template.recurring_type,
                    v_template.end_date,
                    v_template.is_fixed_expense,
                    v_template.fixed_expense_category_id
                );

                v_transactions_count := v_transactions_count + 1;

                -- 다음 날짜 계산
                v_current_date := calculate_next_recurring_date(
                    v_current_date,
                    v_template.recurring_type,
                    v_template.recurring_day
                );
            END LOOP;

            -- last_generated_date 업데이트 (오늘까지 생성했으면 오늘 날짜로)
            IF v_transactions_count > 0 THEN
                UPDATE recurring_templates
                SET last_generated_date = v_today,
                    updated_at = NOW()
                WHERE id = v_template.id;
            END IF;

            -- 종료일이 지났으면 비활성화
            IF v_template.end_date IS NOT NULL AND v_template.end_date < v_today THEN
                UPDATE recurring_templates
                SET is_active = FALSE,
                    updated_at = NOW()
                WHERE id = v_template.id;
            END IF;

            template_id := v_template.id;
            transactions_created := v_transactions_count;
            error_message := NULL;
            RETURN NEXT;

        EXCEPTION WHEN OTHERS THEN
            template_id := v_template.id;
            transactions_created := 0;
            error_message := SQLERRM;
            RETURN NEXT;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- pg_cron 스케줄 등록 (매일 00:00 KST = 15:00 UTC 전날)
-- 한국 시간 00:00은 UTC 15:00 (전날)
SELECT cron.schedule(
    'generate-recurring-transactions',
    '0 15 * * *',  -- 매일 UTC 15:00 (KST 00:00)
    'SELECT * FROM generate_recurring_transactions()'
);

-- Realtime 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE recurring_templates;

-- 코멘트 추가
COMMENT ON TABLE recurring_templates IS '반복 거래 템플릿 테이블 - 매일 자동으로 거래 생성';
COMMENT ON COLUMN recurring_templates.last_generated_date IS '마지막으로 거래가 생성된 날짜';
COMMENT ON COLUMN recurring_templates.recurring_day IS '매월/매년 반복 시 실행할 날짜 (1-31)';
COMMENT ON COLUMN recurring_templates.end_date IS 'NULL이면 무기한 반복';
COMMENT ON FUNCTION generate_recurring_transactions() IS '매일 00:00에 실행되어 오늘까지의 반복 거래를 자동 생성';
