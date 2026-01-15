-- FCM 토큰은 기기에 고유하므로, 같은 토큰이 다른 사용자에게 등록되면 안 됨
-- 새 토큰이 삽입되거나 업데이트될 때, 해당 토큰이 다른 사용자에게 등록되어 있으면 삭제

-- 기존 중복 토큰 정리 (현재 user_id가 아닌 다른 사용자의 동일 토큰 삭제)
-- 이 함수는 INSERT/UPDATE 전에 호출됨
CREATE OR REPLACE FUNCTION cleanup_duplicate_fcm_tokens()
RETURNS TRIGGER AS $$
BEGIN
    -- 같은 토큰이 다른 사용자에게 등록되어 있으면 삭제
    DELETE FROM fcm_tokens 
    WHERE token = NEW.token 
    AND user_id != NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성 (INSERT와 UPDATE 전에 실행)
DROP TRIGGER IF EXISTS cleanup_fcm_tokens_trigger ON fcm_tokens;
CREATE TRIGGER cleanup_fcm_tokens_trigger
    BEFORE INSERT OR UPDATE ON fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_duplicate_fcm_tokens();

-- 토큰 컬럼에 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);
