-- transactions 테이블에 recurring_template_id 컬럼 추가
-- 반복 거래 삭제 시 템플릿 비활성화를 위한 역참조

ALTER TABLE house.transactions
ADD COLUMN IF NOT EXISTS recurring_template_id UUID REFERENCES house.recurring_templates(id) ON DELETE SET NULL;

-- 인덱스 추가 (partial index - NULL이 아닌 경우만)
CREATE INDEX IF NOT EXISTS idx_transactions_recurring_template_id
ON house.transactions(recurring_template_id)
WHERE recurring_template_id IS NOT NULL;

-- generate_recurring_transactions 함수 업데이트
-- INSERT 시 recurring_template_id를 포함하도록 수정
CREATE OR REPLACE FUNCTION house.generate_recurring_transactions()
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
    FOR v_template IN
        SELECT * FROM house.recurring_templates
        WHERE is_active = TRUE
        AND (end_date IS NULL OR end_date >= v_today)
    LOOP
        BEGIN
            v_transactions_count := 0;

            IF v_template.last_generated_date IS NULL THEN
                v_current_date := v_template.start_date;
            ELSE
                v_current_date := house.calculate_next_recurring_date(
                    v_template.last_generated_date,
                    v_template.recurring_type,
                    v_template.recurring_day
                );
            END IF;

            WHILE v_current_date <= v_today AND
                  (v_template.end_date IS NULL OR v_current_date <= v_template.end_date)
            LOOP
                INSERT INTO house.transactions (
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
                    fixed_expense_category_id,
                    recurring_template_id
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
                    v_template.fixed_expense_category_id,
                    v_template.id
                );

                v_transactions_count := v_transactions_count + 1;

                v_current_date := house.calculate_next_recurring_date(
                    v_current_date,
                    v_template.recurring_type,
                    v_template.recurring_day
                );
            END LOOP;

            IF v_transactions_count > 0 THEN
                UPDATE house.recurring_templates
                SET last_generated_date = v_today,
                    updated_at = NOW()
                WHERE id = v_template.id;
            END IF;

            IF v_template.end_date IS NOT NULL AND v_template.end_date < v_today THEN
                UPDATE house.recurring_templates
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
