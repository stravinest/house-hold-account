-- 034_add_auto_save_features.sql
-- SMS/푸시 알림 기반 거래 자동 저장 기능

-- ============================================
-- 1. payment_methods 테이블 확장
-- ============================================

-- 자동 저장 모드: manual(수동), suggest(제안), auto(자동)
ALTER TABLE house.payment_methods
ADD COLUMN IF NOT EXISTS auto_save_mode TEXT DEFAULT 'manual' 
  CHECK (auto_save_mode IN ('manual', 'suggest', 'auto'));

-- 기본 카테고리 (자동 분류 실패 시 사용)
ALTER TABLE house.payment_methods
ADD COLUMN IF NOT EXISTS default_category_id UUID REFERENCES house.categories(id) ON DELETE SET NULL;

COMMENT ON COLUMN house.payment_methods.auto_save_mode IS '자동 저장 모드: manual(수동), suggest(제안), auto(자동)';
COMMENT ON COLUMN house.payment_methods.default_category_id IS '자동 분류 실패 시 기본 카테고리';

-- ============================================
-- 2. learned_sms_formats 테이블 (학습된 SMS 포맷)
-- ============================================

CREATE TABLE IF NOT EXISTS house.learned_sms_formats (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    payment_method_id UUID NOT NULL REFERENCES house.payment_methods(id) ON DELETE CASCADE,
    
    -- 발신자 매칭
    sender_pattern TEXT NOT NULL,           -- 발신자 번호/이름 패턴 (예: '1644-9999', 'KB국민')
    sender_keywords TEXT[],                 -- 추가 키워드 (예: ['KB', '국민', '카드'])
    
    -- 파싱 패턴 (정규식)
    amount_regex TEXT NOT NULL,             -- 금액 추출 정규식
    type_keywords JSONB DEFAULT '{"income": ["입금", "충전"], "expense": ["출금", "결제", "승인", "이체"]}',
    merchant_regex TEXT,                    -- 상호명 추출 정규식 (선택)
    date_regex TEXT,                        -- 날짜 추출 정규식 (선택)
    
    -- 샘플 데이터 (학습용)
    sample_sms TEXT,                        -- 학습에 사용된 샘플 SMS
    
    -- 메타데이터
    is_system BOOLEAN DEFAULT FALSE,        -- 시스템 제공 vs 사용자 학습
    confidence DECIMAL(3,2) DEFAULT 0.8,    -- 신뢰도 (0.00 ~ 1.00)
    match_count INT DEFAULT 0,              -- 매칭 성공 횟수
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(payment_method_id, sender_pattern)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_learned_sms_formats_payment_method 
  ON house.learned_sms_formats(payment_method_id);

COMMENT ON TABLE house.learned_sms_formats IS '학습된 SMS 포맷 패턴';
COMMENT ON COLUMN house.learned_sms_formats.sender_pattern IS 'SMS 발신자 패턴 (번호 또는 이름)';
COMMENT ON COLUMN house.learned_sms_formats.amount_regex IS '금액 추출 정규식';
COMMENT ON COLUMN house.learned_sms_formats.confidence IS '파싱 신뢰도 (0.00 ~ 1.00)';

-- ============================================
-- 3. pending_transactions 테이블 (대기 중인 거래)
-- ============================================

CREATE TABLE IF NOT EXISTS house.pending_transactions (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES house.ledgers(id) ON DELETE CASCADE,
    payment_method_id UUID REFERENCES house.payment_methods(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES house.profiles(id) ON DELETE CASCADE,
    
    -- 원본 데이터
    source_type TEXT NOT NULL CHECK (source_type IN ('sms', 'notification')),
    source_sender TEXT,                     -- SMS 발신자 또는 앱 패키지명
    source_content TEXT NOT NULL,           -- 원본 메시지 전체
    source_timestamp TIMESTAMPTZ NOT NULL,  -- 원본 메시지 수신 시간
    
    -- 파싱된 데이터
    parsed_amount INT,
    parsed_type TEXT CHECK (parsed_type IN ('income', 'expense')),
    parsed_merchant TEXT,                   -- 상호명
    parsed_category_id UUID REFERENCES house.categories(id) ON DELETE SET NULL,
    parsed_date DATE,
    
    -- 상태 관리
    status TEXT NOT NULL DEFAULT 'pending' 
      CHECK (status IN ('pending', 'confirmed', 'rejected', 'converted')),
    -- pending: 대기 중 (사용자 확인 필요)
    -- confirmed: 사용자 승인 (거래로 변환 예정)
    -- rejected: 사용자 거부 (무시)
    -- converted: 거래로 변환 완료
    
    -- 변환된 거래 참조
    transaction_id UUID UNIQUE REFERENCES house.transactions(id) ON DELETE SET NULL,
    
    -- 중복 체크용 해시 (금액 + 결제수단 + 시간대)
    duplicate_hash TEXT,
    
    -- 메타데이터
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days')
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_pending_transactions_ledger_status 
  ON house.pending_transactions(ledger_id, status);
CREATE INDEX IF NOT EXISTS idx_pending_transactions_user_status 
  ON house.pending_transactions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_pending_transactions_expires 
  ON house.pending_transactions(expires_at) 
  WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_pending_transactions_duplicate_hash 
  ON house.pending_transactions(duplicate_hash, created_at DESC);

COMMENT ON TABLE house.pending_transactions IS '대기 중인 자동 감지 거래';
COMMENT ON COLUMN house.pending_transactions.status IS 'pending(대기), confirmed(승인), rejected(거부), converted(변환완료)';
COMMENT ON COLUMN house.pending_transactions.duplicate_hash IS '중복 체크용 해시 (금액+결제수단+시간대)';

-- ============================================
-- 4. merchant_category_rules 테이블 (상호명-카테고리 매핑)
-- ============================================

CREATE TABLE IF NOT EXISTS house.merchant_category_rules (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    ledger_id UUID NOT NULL REFERENCES house.ledgers(id) ON DELETE CASCADE,
    
    -- 매칭 규칙
    merchant_pattern TEXT NOT NULL,         -- 상호명 패턴 (키워드 또는 정규식)
    is_regex BOOLEAN DEFAULT FALSE,         -- 정규식 여부
    
    -- 매핑 대상
    category_id UUID NOT NULL REFERENCES house.categories(id) ON DELETE CASCADE,
    
    -- 우선순위 (높을수록 먼저 적용)
    priority INT DEFAULT 0,
    
    -- 시스템 제공 vs 사용자 정의
    is_system BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(ledger_id, merchant_pattern)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_merchant_category_rules_ledger 
  ON house.merchant_category_rules(ledger_id, priority DESC);

COMMENT ON TABLE house.merchant_category_rules IS '상호명 -> 카테고리 자동 매핑 규칙';

-- ============================================
-- 5. transactions 테이블 확장
-- ============================================

ALTER TABLE house.transactions
ADD COLUMN IF NOT EXISTS source_type TEXT DEFAULT 'manual' 
  CHECK (source_type IN ('manual', 'sms', 'notification', 'recurring'));

COMMENT ON COLUMN house.transactions.source_type IS '거래 출처: manual(수동), sms(SMS), notification(알림), recurring(반복)';

-- ============================================
-- 6. RLS 정책
-- ============================================

-- learned_sms_formats RLS
ALTER TABLE house.learned_sms_formats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "learned_sms_formats_select_policy"
    ON house.learned_sms_formats FOR SELECT
    USING (
        payment_method_id IN (
            SELECT pm.id FROM house.payment_methods pm
            JOIN house.ledger_members lm ON pm.ledger_id = lm.ledger_id
            WHERE lm.user_id = auth.uid()
        )
    );

CREATE POLICY "learned_sms_formats_insert_policy"
    ON house.learned_sms_formats FOR INSERT
    WITH CHECK (
        payment_method_id IN (
            SELECT pm.id FROM house.payment_methods pm
            JOIN house.ledger_members lm ON pm.ledger_id = lm.ledger_id
            WHERE lm.user_id = auth.uid()
        )
    );

CREATE POLICY "learned_sms_formats_update_policy"
    ON house.learned_sms_formats FOR UPDATE
    USING (
        payment_method_id IN (
            SELECT pm.id FROM house.payment_methods pm
            JOIN house.ledger_members lm ON pm.ledger_id = lm.ledger_id
            WHERE lm.user_id = auth.uid()
        )
    );

CREATE POLICY "learned_sms_formats_delete_policy"
    ON house.learned_sms_formats FOR DELETE
    USING (
        payment_method_id IN (
            SELECT pm.id FROM house.payment_methods pm
            JOIN house.ledger_members lm ON pm.ledger_id = lm.ledger_id
            WHERE lm.user_id = auth.uid()
        )
    );

-- pending_transactions RLS
ALTER TABLE house.pending_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pending_transactions_select_policy"
    ON house.pending_transactions FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "pending_transactions_insert_policy"
    ON house.pending_transactions FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members WHERE user_id = auth.uid()
        )
        AND user_id = auth.uid()
    );

CREATE POLICY "pending_transactions_update_policy"
    ON house.pending_transactions FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "pending_transactions_delete_policy"
    ON house.pending_transactions FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members WHERE user_id = auth.uid()
        )
    );

-- merchant_category_rules RLS
ALTER TABLE house.merchant_category_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "merchant_category_rules_select_policy"
    ON house.merchant_category_rules FOR SELECT
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "merchant_category_rules_insert_policy"
    ON house.merchant_category_rules FOR INSERT
    WITH CHECK (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members 
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "merchant_category_rules_update_policy"
    ON house.merchant_category_rules FOR UPDATE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members 
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "merchant_category_rules_delete_policy"
    ON house.merchant_category_rules FOR DELETE
    USING (
        ledger_id IN (
            SELECT ledger_id FROM house.ledger_members 
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
        AND is_system = FALSE
    );

-- ============================================
-- 7. 헬퍼 함수
-- ============================================

-- 만료된 대기 거래 정리 함수
CREATE OR REPLACE FUNCTION house.cleanup_expired_pending_transactions()
RETURNS INT AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM house.pending_transactions 
    WHERE status = 'pending' AND expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 중복 거래 체크 함수 (3분 이내 동일 금액 + 결제수단)
CREATE OR REPLACE FUNCTION house.check_duplicate_transaction(
    p_amount INT,
    p_payment_method_id UUID,
    p_timestamp TIMESTAMPTZ,
    p_minutes INT DEFAULT 3
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM house.transactions t
        WHERE t.payment_method_id = p_payment_method_id
          AND t.amount = p_amount
          AND t.created_at BETWEEN (p_timestamp - (p_minutes || ' minutes')::INTERVAL) 
                               AND (p_timestamp + (p_minutes || ' minutes')::INTERVAL)
    ) OR EXISTS (
        SELECT 1 FROM house.pending_transactions pt
        WHERE pt.payment_method_id = p_payment_method_id
          AND pt.parsed_amount = p_amount
          AND pt.status IN ('pending', 'confirmed', 'converted')
          AND pt.source_timestamp BETWEEN (p_timestamp - (p_minutes || ' minutes')::INTERVAL) 
                                      AND (p_timestamp + (p_minutes || ' minutes')::INTERVAL)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION house.check_duplicate_transaction IS '중복 거래 체크 (3분 이내 동일 금액 + 결제수단)';

-- ============================================
-- 8. 시스템 기본 SMS 포맷 삽입 함수
-- ============================================

CREATE OR REPLACE FUNCTION house.insert_default_sms_formats(p_payment_method_id UUID)
RETURNS void AS $$
BEGIN
    -- KB국민 패턴
    INSERT INTO house.learned_sms_formats 
      (payment_method_id, sender_pattern, sender_keywords, amount_regex, merchant_regex, date_regex, is_system, confidence)
    VALUES 
      (p_payment_method_id, '1644-9999', ARRAY['KB', '국민'], 
       '(\d{1,3}(?:,\d{3})*)원', '(?:에서|at)\s*(.+?)(?:\s|$)', '(\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2})', TRUE, 0.95),
      (p_payment_method_id, 'KB국민', ARRAY['KB', '국민', '카드'], 
       '(\d{1,3}(?:,\d{3})*)원', '(?:가맹점|상호)\s*(.+?)(?:\s|$)', '(\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2})', TRUE, 0.95)
    ON CONFLICT (payment_method_id, sender_pattern) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기본 상호명-카테고리 규칙 삽입 함수
CREATE OR REPLACE FUNCTION house.insert_default_merchant_rules(p_ledger_id UUID)
RETURNS void AS $$
DECLARE
    v_food_category_id UUID;
    v_transport_category_id UUID;
    v_shopping_category_id UUID;
BEGIN
    -- 카테고리 ID 조회 (한글 이름 기준)
    SELECT id INTO v_food_category_id FROM house.categories 
      WHERE ledger_id = p_ledger_id AND name = '식비' AND type = 'expense' LIMIT 1;
    SELECT id INTO v_transport_category_id FROM house.categories 
      WHERE ledger_id = p_ledger_id AND name = '교통' AND type = 'expense' LIMIT 1;
    SELECT id INTO v_shopping_category_id FROM house.categories 
      WHERE ledger_id = p_ledger_id AND name = '쇼핑' AND type = 'expense' LIMIT 1;
    
    -- 식비 규칙
    IF v_food_category_id IS NOT NULL THEN
        INSERT INTO house.merchant_category_rules 
          (ledger_id, merchant_pattern, category_id, priority, is_system)
        VALUES 
          (p_ledger_id, '스타벅스|커피|카페|베이커리|빵집', v_food_category_id, 100, TRUE),
          (p_ledger_id, '맥도날드|버거킹|KFC|롯데리아|피자|치킨|배달', v_food_category_id, 100, TRUE),
          (p_ledger_id, '편의점|CU|GS25|세븐일레븐|이마트24|미니스톱', v_food_category_id, 50, TRUE)
        ON CONFLICT (ledger_id, merchant_pattern) DO NOTHING;
    END IF;
    
    -- 교통 규칙
    IF v_transport_category_id IS NOT NULL THEN
        INSERT INTO house.merchant_category_rules 
          (ledger_id, merchant_pattern, category_id, priority, is_system)
        VALUES 
          (p_ledger_id, '주유소|SK에너지|GS칼텍스|현대오일|S-OIL|충전소', v_transport_category_id, 100, TRUE),
          (p_ledger_id, '택시|카카오T|타다|우버|UBER', v_transport_category_id, 100, TRUE),
          (p_ledger_id, '지하철|버스|교통카드|티머니|캐시비', v_transport_category_id, 100, TRUE)
        ON CONFLICT (ledger_id, merchant_pattern) DO NOTHING;
    END IF;
    
    -- 쇼핑 규칙
    IF v_shopping_category_id IS NOT NULL THEN
        INSERT INTO house.merchant_category_rules 
          (ledger_id, merchant_pattern, category_id, priority, is_system)
        VALUES 
          (p_ledger_id, '쿠팡|네이버페이|11번가|G마켓|옥션|위메프|티몬', v_shopping_category_id, 100, TRUE),
          (p_ledger_id, '이마트|홈플러스|롯데마트|코스트코|트레이더스', v_shopping_category_id, 100, TRUE),
          (p_ledger_id, '다이소|올리브영|무신사|지그재그', v_shopping_category_id, 50, TRUE)
        ON CONFLICT (ledger_id, merchant_pattern) DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION house.insert_default_merchant_rules IS '기본 상호명-카테고리 매핑 규칙 삽입';
