-- 반복 거래 cron을 KST 00:01에 실행되도록 변경
-- 기존: UTC 15:00 (KST 00:00) + CURRENT_DATE(UTC) -> 당일 거래가 다음날 KST 00:00에 생성됨
-- 변경: UTC 15:01 (KST 00:01) + KST 날짜 기준 -> 당일 거래가 당일 KST 00:01에 생성됨

-- 1. generate_recurring_transactions 함수에서 CURRENT_DATE를 KST 기준으로 변경
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
    v_today DATE := (NOW() AT TIME ZONE 'Asia/Seoul')::DATE;
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

            -- 오늘(KST)까지의 거래 생성
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

            -- last_generated_date 업데이트
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

-- 2. 기존 cron 스케줄 삭제 후 재등록
SELECT cron.unschedule('generate-recurring-transactions');

-- KST 00:01 = UTC 15:01 (전날)
SELECT cron.schedule(
    'generate-recurring-transactions',
    '1 15 * * *',
    'SELECT * FROM generate_recurring_transactions()'
);

COMMENT ON FUNCTION generate_recurring_transactions() IS '매일 KST 00:01에 실행되어 오늘(KST)까지의 반복 거래를 자동 생성';
