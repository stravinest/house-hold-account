-- 048_add_increment_push_format_match_count.sql
-- Push 알림 포맷 매칭 카운트 원자적 증가 RPC 함수

-- ============================================
-- increment_push_format_match_count 함수
-- ============================================
-- 동시성 문제 없이 match_count를 원자적으로 증가시키는 함수
-- read-then-write 패턴의 race condition 문제 해결
-- learned_sms_formats의 increment_sms_format_match_count와 동일한 패턴

CREATE OR REPLACE FUNCTION house.increment_push_format_match_count(format_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE house.learned_push_formats
  SET match_count = COALESCE(match_count, 0) + 1,
      updated_at = NOW()
  WHERE id = format_id;
END;
$$;

COMMENT ON FUNCTION house.increment_push_format_match_count IS 'Push 알림 포맷 매칭 카운트 원자적 증가 (race condition 방지)';

-- RPC 함수 실행 권한 부여
GRANT EXECUTE ON FUNCTION house.increment_push_format_match_count(UUID) TO authenticated;
