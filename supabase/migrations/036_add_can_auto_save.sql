-- 036_add_can_auto_save.sql
-- 결제수단의 자동 수집 지원 여부 컬럼 추가 및 정책 적용

-- 1. can_auto_save 컬럼 추가
-- 중요: 기본값을 FALSE로 설정하여 '직접 입력'된 수단들이 자동으로 미지원 상태가 되도록 함.
ALTER TABLE house.payment_methods
ADD COLUMN IF NOT EXISTS can_auto_save BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN house.payment_methods.can_auto_save IS '자동 수집 지원 여부 (TRUE: 지원, FALSE: 미지원/직접입력)';

-- 2. 화이트리스트 기반 업데이트
-- 현재 앱에서 공식 지원하는 템플릿(KB, 농협, 경기지역화폐)만 TRUE로 활성화
UPDATE house.payment_methods
SET can_auto_save = TRUE
WHERE name IN ('KB국민카드', 'NH농협카드', '경기지역화폐');

-- 3. Trigger 업데이트 (새로운 가계부 생성 시 정책)
CREATE OR REPLACE FUNCTION handle_new_ledger_payment_methods()
RETURNS TRIGGER AS $$
BEGIN
    -- 기본 생성되는 항목들도 템플릿 기반이 아니므로 기본적으로는 자동수집 OFF (FALSE)
    -- 사용자가 나중에 위자드를 통해 정확한 금융사를 추가하도록 유도
    INSERT INTO house.payment_methods (ledger_id, name, icon, color, is_default, sort_order, can_auto_save) VALUES
        (NEW.id, '현금', '', '#4CAF50', TRUE, 1, FALSE),
        (NEW.id, '카드', '', '#2196F3', FALSE, 2, FALSE); 
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
