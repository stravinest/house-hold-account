-- 카테고리를 선택사항으로 변경
-- 거래 등록 시 카테고리 없이도 저장 가능하도록 수정

-- transactions 테이블의 category_id를 nullable로 변경
ALTER TABLE transactions ALTER COLUMN category_id DROP NOT NULL;

-- 참고: 기본 카테고리 자동 생성 트리거는 유지
-- 기존 사용자에게 영향을 줄 수 있으므로 트리거는 그대로 둠
-- 신규 사용자는 기본 카테고리가 생성되지만, 사용은 선택사항임
