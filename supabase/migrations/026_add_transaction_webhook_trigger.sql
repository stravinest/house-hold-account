-- transactions 테이블 변경 시 send-push-notification Edge Function 호출
-- pg_net extension을 사용하여 비동기 HTTP 요청

CREATE OR REPLACE FUNCTION house.notify_transaction_change()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
  edge_function_url text;
BEGIN
  -- Edge Function URL
  edge_function_url := 'https://qcpjxxgnqdbngyepevmt.supabase.co/functions/v1/send-push-notification';
  
  -- Webhook payload 생성
  payload := jsonb_build_object(
    'type', TG_OP,
    'table', TG_TABLE_NAME,
    'schema', TG_TABLE_SCHEMA,
    'record', CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
    'old_record', CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE to_jsonb(OLD) END
  );
  
  -- pg_net을 사용하여 비동기 HTTP POST 요청
  PERFORM net.http_post(
    url := edge_function_url,
    body := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json'
    )
  );
  
  -- 트리거 결과 반환
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기존 트리거가 있으면 삭제
DROP TRIGGER IF EXISTS on_transaction_change ON house.transactions;

-- 트리거 생성 (INSERT, UPDATE, DELETE 후 실행)
CREATE TRIGGER on_transaction_change
  AFTER INSERT OR UPDATE OR DELETE ON house.transactions
  FOR EACH ROW
  EXECUTE FUNCTION house.notify_transaction_change();

-- 함수에 대한 주석
COMMENT ON FUNCTION house.notify_transaction_change() IS 'transactions 테이블 변경 시 send-push-notification Edge Function 호출';
