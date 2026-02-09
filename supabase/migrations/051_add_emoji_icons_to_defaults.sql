-- 051_add_emoji_icons_to_defaults.sql
-- 기본 카테고리/결제수단에 Material icon 이름 추가 및 카테고리 자동 생성 트리거 복원

-- ============================================================
-- Part 1: 기존 데이터 소급 적용 (UPDATE)
-- 조건: icon이 비어있거나 기존 Material icon 이름인 경우만 업데이트
-- 사용자가 직접 설정한 값은 보존
-- ============================================================

-- 지출 카테고리 icon 업데이트
UPDATE house.categories SET icon = 'restaurant' WHERE name = '식비' AND type = 'expense' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'directions_bus' WHERE name = '교통' AND type = 'expense' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'shopping_cart' WHERE name = '쇼핑' AND type = 'expense' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'home' WHERE name = '생활' AND type = 'expense' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'call' WHERE name = '통신' AND type = 'expense' AND (icon = '' OR icon IS NULL OR icon = 'phone_android');
UPDATE house.categories SET icon = 'local_hospital' WHERE name = '의료' AND type = 'expense' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'movie' WHERE name = '문화' AND type = 'expense' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'menu_book' WHERE name = '교육' AND type = 'expense' AND (icon = '' OR icon IS NULL OR icon = 'school');
UPDATE house.categories SET icon = 'receipt_long' WHERE name = '기타 지출' AND type = 'expense' AND (icon = '' OR icon IS NULL OR icon = 'money_off');

-- 수입 카테고리 icon 업데이트
UPDATE house.categories SET icon = 'account_balance_wallet' WHERE name = '급여' AND type = 'income' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'work' WHERE name = '부업' AND type = 'income' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'redeem' WHERE name = '용돈' AND type = 'income' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'account_balance' WHERE name = '이자' AND type = 'income' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'attach_money' WHERE name = '기타 수입' AND type = 'income' AND (icon = '' OR icon IS NULL);

-- 자산 카테고리 icon 업데이트
UPDATE house.categories SET icon = 'lock' WHERE name = '정기예금' AND type = 'asset' AND (icon = '' OR icon IS NULL OR icon = 'savings');
UPDATE house.categories SET icon = 'savings' WHERE name = '적금' AND type = 'asset' AND (icon = '' OR icon IS NULL OR icon = 'account_balance');
UPDATE house.categories SET icon = 'trending_up' WHERE name = '주식' AND type = 'asset' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'pie_chart' WHERE name = '펀드' AND type = 'asset' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'apartment' WHERE name = '부동산' AND type = 'asset' AND (icon = '' OR icon IS NULL OR icon = 'home');
UPDATE house.categories SET icon = 'currency_bitcoin' WHERE name = '암호화폐' AND type = 'asset' AND (icon = '' OR icon IS NULL);
UPDATE house.categories SET icon = 'diamond' WHERE name = '기타 자산' AND type = 'asset' AND (icon = '' OR icon IS NULL OR icon = 'wallet');

-- 고정비 카테고리: '월세/관리비'를 '월세'와 '관리비'로 분리
UPDATE house.fixed_expense_categories SET name = '월세', icon = 'house' WHERE name = '월세/관리비';

-- '관리비' 카테고리 새로 추가 (기존 가계부에)
INSERT INTO house.fixed_expense_categories (ledger_id, name, icon, color, sort_order)
SELECT DISTINCT fec.ledger_id, '관리비', 'domain', '#FF8A65', 2
FROM house.fixed_expense_categories fec
WHERE fec.name = '월세'
AND NOT EXISTS (
    SELECT 1 FROM house.fixed_expense_categories
    WHERE ledger_id = fec.ledger_id AND name = '관리비'
);

-- 기존 카테고리들 sort_order 재정렬
UPDATE house.fixed_expense_categories SET sort_order = 7 WHERE name = '대출 상환';
UPDATE house.fixed_expense_categories SET sort_order = 6 WHERE name = '구독료';
UPDATE house.fixed_expense_categories SET sort_order = 5 WHERE name = '통신비';
UPDATE house.fixed_expense_categories SET sort_order = 4 WHERE name = '보험료';
UPDATE house.fixed_expense_categories SET sort_order = 2 WHERE name = '관리비';
UPDATE house.fixed_expense_categories SET sort_order = 1 WHERE name = '월세';

-- 나머지 고정비 카테고리 icon 업데이트
UPDATE house.fixed_expense_categories SET icon = 'shield' WHERE name = '보험료' AND (icon = '' OR icon IS NULL);
UPDATE house.fixed_expense_categories SET icon = 'cell_tower' WHERE name = '통신비' AND (icon = '' OR icon IS NULL);
UPDATE house.fixed_expense_categories SET icon = 'subscriptions' WHERE name = '구독료' AND (icon = '' OR icon IS NULL);
UPDATE house.fixed_expense_categories SET icon = 'request_quote' WHERE name = '대출 상환' AND (icon = '' OR icon IS NULL);

-- 결제수단 icon 업데이트
UPDATE house.payment_methods SET icon = 'payments' WHERE name = '현금' AND (icon = '' OR icon IS NULL);
UPDATE house.payment_methods SET icon = 'credit_card' WHERE name = '카드' AND (icon = '' OR icon IS NULL);

-- ============================================================
-- Part 2: 지출/수입/자산 카테고리 자동 생성 트리거 복원
-- ============================================================

CREATE OR REPLACE FUNCTION house.handle_new_ledger_categories()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO house.categories (ledger_id, name, icon, color, type, is_default, sort_order) VALUES
        (NEW.id, '식비', 'restaurant', '#FF6B6B', 'expense', TRUE, 1),
        (NEW.id, '교통', 'directions_bus', '#4ECDC4', 'expense', TRUE, 2),
        (NEW.id, '쇼핑', 'shopping_cart', '#FFE66D', 'expense', TRUE, 3),
        (NEW.id, '생활', 'home', '#95E1D3', 'expense', TRUE, 4),
        (NEW.id, '통신', 'call', '#A8DADC', 'expense', TRUE, 5),
        (NEW.id, '의료', 'local_hospital', '#F4A261', 'expense', TRUE, 6),
        (NEW.id, '문화', 'movie', '#E76F51', 'expense', TRUE, 7),
        (NEW.id, '교육', 'menu_book', '#2A9D8F', 'expense', TRUE, 8),
        (NEW.id, '기타 지출', 'receipt_long', '#6C757D', 'expense', TRUE, 9);

    INSERT INTO house.categories (ledger_id, name, icon, color, type, is_default, sort_order) VALUES
        (NEW.id, '급여', 'account_balance_wallet', '#4CAF50', 'income', TRUE, 1),
        (NEW.id, '부업', 'work', '#8BC34A', 'income', TRUE, 2),
        (NEW.id, '용돈', 'redeem', '#CDDC39', 'income', TRUE, 3),
        (NEW.id, '이자', 'account_balance', '#00BCD4', 'income', TRUE, 4),
        (NEW.id, '기타 수입', 'attach_money', '#9E9E9E', 'income', TRUE, 5);

    INSERT INTO house.categories (ledger_id, name, icon, color, type, is_default, sort_order) VALUES
        (NEW.id, '정기예금', 'lock', '#4CAF50', 'asset', TRUE, 1),
        (NEW.id, '적금', 'savings', '#66BB6A', 'asset', TRUE, 2),
        (NEW.id, '주식', 'trending_up', '#2196F3', 'asset', TRUE, 3),
        (NEW.id, '펀드', 'pie_chart', '#1976D2', 'asset', TRUE, 4),
        (NEW.id, '부동산', 'apartment', '#FF9800', 'asset', TRUE, 5),
        (NEW.id, '암호화폐', 'currency_bitcoin', '#FFC107', 'asset', TRUE, 6),
        (NEW.id, '기타 자산', 'diamond', '#9E9E9E', 'asset', TRUE, 7);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ledger_created_categories ON house.ledgers;
CREATE TRIGGER on_ledger_created_categories
    AFTER INSERT ON house.ledgers
    FOR EACH ROW EXECUTE FUNCTION house.handle_new_ledger_categories();

-- ============================================================
-- Part 3: 기존 트리거 업데이트
-- ============================================================

CREATE OR REPLACE FUNCTION house.handle_new_ledger_fixed_expense()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO house.fixed_expense_settings (ledger_id, include_in_expense)
    VALUES (NEW.id, FALSE);

    INSERT INTO house.fixed_expense_categories (ledger_id, name, icon, color, sort_order) VALUES
        (NEW.id, '월세', 'house', '#FF6B6B', 1),
        (NEW.id, '관리비', 'domain', '#FF8A65', 2),
        (NEW.id, '보험료', 'shield', '#4ECDC4', 3),
        (NEW.id, '대출 상환', 'request_quote', '#FFEAA7', 4),
        (NEW.id, '통신비', 'cell_tower', '#45B7D1', 5),
        (NEW.id, '구독료', 'subscriptions', '#96CEB4', 6);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION house.handle_new_ledger_payment_methods()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO house.payment_methods (ledger_id, name, icon, color, is_default, sort_order, can_auto_save) VALUES
        (NEW.id, '현금', 'payments', '#4CAF50', TRUE, 1, FALSE),
        (NEW.id, '카드', 'credit_card', '#2196F3', FALSE, 2, FALSE);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Part 4: 누락된 기본 카테고리 소급 생성
-- ============================================================

INSERT INTO house.categories (ledger_id, name, icon, color, type, is_default, sort_order)
SELECT l.id, c.name, c.icon, c.color, 'expense', TRUE, c.sort_order
FROM house.ledgers l
CROSS JOIN (
    VALUES
        ('식비', 'restaurant', '#FF6B6B', 1),
        ('교통', 'directions_bus', '#4ECDC4', 2),
        ('쇼핑', 'shopping_cart', '#FFE66D', 3),
        ('생활', 'home', '#95E1D3', 4),
        ('통신', 'call', '#A8DADC', 5),
        ('의료', 'local_hospital', '#F4A261', 6),
        ('문화', 'movie', '#E76F51', 7),
        ('교육', 'menu_book', '#2A9D8F', 8),
        ('기타 지출', 'receipt_long', '#6C757D', 9)
) AS c(name, icon, color, sort_order)
WHERE NOT EXISTS (
    SELECT 1 FROM house.categories
    WHERE categories.ledger_id = l.id
    AND categories.name = c.name
    AND categories.type = 'expense'
);

INSERT INTO house.categories (ledger_id, name, icon, color, type, is_default, sort_order)
SELECT l.id, c.name, c.icon, c.color, 'income', TRUE, c.sort_order
FROM house.ledgers l
CROSS JOIN (
    VALUES
        ('급여', 'account_balance_wallet', '#4CAF50', 1),
        ('부업', 'work', '#8BC34A', 2),
        ('용돈', 'redeem', '#CDDC39', 3),
        ('이자', 'account_balance', '#00BCD4', 4),
        ('기타 수입', 'attach_money', '#9E9E9E', 5)
) AS c(name, icon, color, sort_order)
WHERE NOT EXISTS (
    SELECT 1 FROM house.categories
    WHERE categories.ledger_id = l.id
    AND categories.name = c.name
    AND categories.type = 'income'
);
