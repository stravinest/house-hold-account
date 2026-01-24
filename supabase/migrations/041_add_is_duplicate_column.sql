-- Migration: 041_add_is_duplicate_column.sql
-- Description: pending_transactions 테이블에 is_duplicate 컬럼 추가
-- 기존 duplicateHash는 중복 감지용 해시이고, is_duplicate는 실제 중복 여부를 나타냄

-- is_duplicate 컬럼 추가 (기본값 false)
ALTER TABLE pending_transactions
ADD COLUMN IF NOT EXISTS is_duplicate BOOLEAN DEFAULT FALSE;

-- 기존 데이터 업데이트: duplicateHash가 있으면서 다른 거래와 중복되는 경우에만 true로 설정
-- (이 마이그레이션 이전에 생성된 데이터는 모두 false로 유지)
COMMENT ON COLUMN pending_transactions.is_duplicate IS '실제 중복 거래 여부. duplicateHash는 중복 감지용 해시로, is_duplicate와 분리됨.';
