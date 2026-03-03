-- source_type 'push' -> 'notification' 통일
-- notification_listener_wrapper에서 'notification'으로 저장하는데
-- category_keyword_mappings에서는 'push'를 사용하여 매핑 조회 실패하는 버그 수정

-- 1. 기존 CHECK constraint 제거
ALTER TABLE house.category_keyword_mappings
DROP CONSTRAINT IF EXISTS category_keyword_mappings_source_type_check;

-- 2. 기존 'push' 데이터를 'notification'으로 변경
UPDATE house.category_keyword_mappings
SET source_type = 'notification'
WHERE source_type = 'push';

-- 3. 새 CHECK constraint 추가 ('sms', 'notification')
ALTER TABLE house.category_keyword_mappings
ADD CONSTRAINT category_keyword_mappings_source_type_check
CHECK (source_type = ANY (ARRAY['sms'::text, 'notification'::text]));
