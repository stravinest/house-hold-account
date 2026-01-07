-- 사용자 프로필에 색상 필드 추가
-- 사용자별 고유 색상으로 캘린더에서 거래를 시각적으로 구분

-- profiles 테이블에 color 컬럼 추가
ALTER TABLE profiles
ADD COLUMN color VARCHAR(7) DEFAULT '#A8D8EA';

-- color 컬럼에 대한 설명 추가
COMMENT ON COLUMN profiles.color IS '사용자 고유 색상 (HEX 코드, 예: #A8D8EA)';

-- color 컬럼에 대한 제약조건 추가 (HEX 코드 형식 검증)
ALTER TABLE profiles
ADD CONSTRAINT check_color_format
CHECK (color ~ '^#[0-9A-Fa-f]{6}$');
