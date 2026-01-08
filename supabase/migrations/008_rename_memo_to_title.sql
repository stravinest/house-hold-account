-- memo 컬럼을 title로 이름 변경 (기존 데이터 유지)
ALTER TABLE transactions RENAME COLUMN memo TO title;

-- 새로운 memo 컬럼 추가 (선택적 메모)
ALTER TABLE transactions ADD COLUMN memo TEXT;
