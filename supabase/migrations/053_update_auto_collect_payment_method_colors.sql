-- 053_update_auto_collect_payment_method_colors.sql
-- 자동수집 결제수단의 브랜드 색상을 공식 색상으로 업데이트
-- 대상: can_auto_save = true인 결제수단 (사용자가 위저드에서 생성한 자동수집 결제수단)

-- ============================================================
-- Part 1: 카드사 (9개) 브랜드 색상 업데이트
-- ============================================================
UPDATE house.payment_methods SET color = '#FFBC00' WHERE name = 'KB국민카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#0046FF' WHERE name = '신한카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#1428A0' WHERE name = '삼성카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#000000' WHERE name = '현대카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#ED1C24' WHERE name = '롯데카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#0056A4' WHERE name = '우리카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#009775' WHERE name = '하나카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#F37321' WHERE name = 'BC카드' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#009A3E' WHERE name = 'NH농협카드' AND can_auto_save = true;

-- ============================================================
-- Part 2: 지역화폐 (7개) 브랜드 색상 업데이트
-- ============================================================
UPDATE house.payment_methods SET color = '#1B5E20' WHERE name = '수원페이' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#4CAF50' WHERE name = '용인와이페이' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#388E3C' WHERE name = '행복화성지역화폐' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#2E7D32' WHERE name = '고양페이' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#43A047' WHERE name = '부천페이' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#7B1FA2' WHERE name = '서울사랑상품권' AND can_auto_save = true;
UPDATE house.payment_methods SET color = '#00838F' WHERE name = '인천이음페이' AND can_auto_save = true;
