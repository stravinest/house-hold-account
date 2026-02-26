-- pending_transactions 3개월 보관기간 설정
-- 3개월이 지난 수집내역(pending, confirmed, rejected, converted 모든 상태)을 자동 삭제
-- 삭제 기준: created_at 기준 3개월 경과 (expires_at과 무관하게 최종 정리)
-- expires_at(30일)은 단기 자동 만료, created_at(3개월)은 장기 전체 정리 역할

-- 기존 함수 제거 (반환 타입 변경 및 역할 통합)
DROP FUNCTION IF EXISTS house.delete_old_pending_transactions();
DROP FUNCTION IF EXISTS house.cleanup_expired_pending_transactions();

-- created_at 인덱스 추가 (삭제 쿼리 성능 최적화)
CREATE INDEX IF NOT EXISTS idx_pending_transactions_created_at
  ON house.pending_transactions(created_at);

-- 3개월 지난 pending_transactions 삭제 함수
CREATE OR REPLACE FUNCTION house.delete_old_pending_transactions()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = house, pg_catalog
AS $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM house.pending_transactions
  WHERE created_at < NOW() - INTERVAL '3 months';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  IF deleted_count > 0 THEN
    RAISE NOTICE 'delete_old_pending_transactions: % rows deleted', deleted_count;
  END IF;

  RETURN deleted_count;
END;
$$;

-- 기존 cron job이 있으면 제거 후 재등록
DO $$
BEGIN
  PERFORM cron.unschedule('delete-old-pending-transactions');
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;

-- 매일 KST 03:00 (UTC 18:00)에 실행하는 cron job 등록
SELECT cron.schedule(
  'delete-old-pending-transactions',
  '0 18 * * *',
  $$SELECT house.delete_old_pending_transactions()$$
);
