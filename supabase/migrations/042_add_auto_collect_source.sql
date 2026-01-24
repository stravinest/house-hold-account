-- Migration: 042_add_auto_collect_source.sql
-- Description: payment_methods 테이블에 auto_collect_source 컬럼 추가
-- SMS 또는 Push 알림 중 하나만 선택하여 중복 수신 문제 방지

-- auto_collect_source 컬럼 추가 (기본값 'sms')
ALTER TABLE house.payment_methods
ADD COLUMN IF NOT EXISTS auto_collect_source TEXT DEFAULT 'sms';

-- 컬럼에 대한 설명 추가
COMMENT ON COLUMN house.payment_methods.auto_collect_source IS '자동 수집 소스 타입: sms(문자), push(푸시 알림). 하나만 선택하여 중복 수신 방지.';

-- CHECK 제약조건 추가 (sms 또는 push만 허용)
ALTER TABLE house.payment_methods
ADD CONSTRAINT check_auto_collect_source
CHECK (auto_collect_source IN ('sms', 'push'));
