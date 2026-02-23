-- 자동수집 금지 키워드 컬럼 추가
-- 감지 키워드에 매칭되더라도 금지 키워드가 포함된 알림은 수집하지 않음

ALTER TABLE house.learned_sms_formats
  ADD COLUMN excluded_keywords TEXT[] DEFAULT '{}';

ALTER TABLE house.learned_push_formats
  ADD COLUMN excluded_keywords TEXT[] DEFAULT '{}';
