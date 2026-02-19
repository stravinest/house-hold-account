-- 거래 삭제 + 반복 템플릿 비활성화를 단일 트랜잭션으로 처리하는 RPC 함수
-- Race condition 방지: 두 작업이 원자적으로 실행됨

CREATE OR REPLACE FUNCTION house.delete_transaction_and_stop_recurring(
  p_transaction_id UUID,
  p_template_id UUID
) RETURNS VOID AS $$
BEGIN
  -- 템플릿 비활성화
  UPDATE house.recurring_templates
  SET is_active = false, updated_at = NOW()
  WHERE id = p_template_id;

  -- 거래 삭제
  DELETE FROM house.transactions WHERE id = p_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
