-- 052_convert_emoji_to_icon_names.sql
-- 051에서 적용된 이모지 아이콘을 Material icon 이름으로 변환
-- 이모지 -> icon name 문자열로 일괄 교체

-- ============================================================
-- Part 1: 지출 카테고리
-- ============================================================
UPDATE house.categories SET icon = 'restaurant' WHERE type = 'expense' AND name = '식비' AND icon NOT IN ('restaurant');
UPDATE house.categories SET icon = 'directions_bus' WHERE type = 'expense' AND name = '교통' AND icon NOT IN ('directions_bus');
UPDATE house.categories SET icon = 'shopping_cart' WHERE type = 'expense' AND name = '쇼핑' AND icon NOT IN ('shopping_cart');
UPDATE house.categories SET icon = 'home' WHERE type = 'expense' AND name = '생활' AND icon NOT IN ('home');
UPDATE house.categories SET icon = 'call' WHERE type = 'expense' AND name = '통신' AND icon NOT IN ('call');
UPDATE house.categories SET icon = 'local_hospital' WHERE type = 'expense' AND name = '의료' AND icon NOT IN ('local_hospital');
UPDATE house.categories SET icon = 'movie' WHERE type = 'expense' AND name = '문화' AND icon NOT IN ('movie');
UPDATE house.categories SET icon = 'menu_book' WHERE type = 'expense' AND name = '교육' AND icon NOT IN ('menu_book');
UPDATE house.categories SET icon = 'receipt_long' WHERE type = 'expense' AND name = '기타 지출' AND icon NOT IN ('receipt_long');

-- ============================================================
-- Part 2: 수입 카테고리
-- ============================================================
UPDATE house.categories SET icon = 'account_balance_wallet' WHERE type = 'income' AND name = '급여' AND icon NOT IN ('account_balance_wallet');
UPDATE house.categories SET icon = 'work' WHERE type = 'income' AND name = '부업' AND icon NOT IN ('work');
UPDATE house.categories SET icon = 'redeem' WHERE type = 'income' AND name = '용돈' AND icon NOT IN ('redeem');
UPDATE house.categories SET icon = 'account_balance' WHERE type = 'income' AND name = '이자' AND icon NOT IN ('account_balance');
UPDATE house.categories SET icon = 'attach_money' WHERE type = 'income' AND name = '기타 수입' AND icon NOT IN ('attach_money');

-- ============================================================
-- Part 3: 자산 카테고리
-- ============================================================
UPDATE house.categories SET icon = 'lock' WHERE type = 'asset' AND name = '정기예금' AND icon NOT IN ('lock');
UPDATE house.categories SET icon = 'savings' WHERE type = 'asset' AND name = '적금' AND icon NOT IN ('savings');
UPDATE house.categories SET icon = 'trending_up' WHERE type = 'asset' AND name = '주식' AND icon NOT IN ('trending_up');
UPDATE house.categories SET icon = 'pie_chart' WHERE type = 'asset' AND name = '펀드' AND icon NOT IN ('pie_chart');
UPDATE house.categories SET icon = 'apartment' WHERE type = 'asset' AND name = '부동산' AND icon NOT IN ('apartment');
UPDATE house.categories SET icon = 'currency_bitcoin' WHERE type = 'asset' AND name = '암호화폐' AND icon NOT IN ('currency_bitcoin');
UPDATE house.categories SET icon = 'diamond' WHERE type = 'asset' AND name = '기타 자산' AND icon NOT IN ('diamond');

-- ============================================================
-- Part 4: 고정비 카테고리
-- ============================================================
UPDATE house.fixed_expense_categories SET icon = 'house' WHERE name = '월세' AND icon NOT IN ('house');
UPDATE house.fixed_expense_categories SET icon = 'domain' WHERE name = '관리비' AND icon NOT IN ('domain');
UPDATE house.fixed_expense_categories SET icon = 'shield' WHERE name = '보험료' AND icon NOT IN ('shield');
UPDATE house.fixed_expense_categories SET icon = 'request_quote' WHERE name = '대출 상환' AND icon NOT IN ('request_quote');
UPDATE house.fixed_expense_categories SET icon = 'cell_tower' WHERE name = '통신비' AND icon NOT IN ('cell_tower');
UPDATE house.fixed_expense_categories SET icon = 'subscriptions' WHERE name = '구독료' AND icon NOT IN ('subscriptions');

-- ============================================================
-- Part 5: 결제수단
-- ============================================================
UPDATE house.payment_methods SET icon = 'payments' WHERE name = '현금' AND icon NOT IN ('payments');
UPDATE house.payment_methods SET icon = 'credit_card' WHERE name = '카드' AND icon NOT IN ('credit_card');

-- ============================================================
-- Part 6: 트리거 함수 업데이트
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
