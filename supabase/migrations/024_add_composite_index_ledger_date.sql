-- ledger_id와 날짜 범위를 사용하는 쿼리 최적화를 위한 복합 인덱스
-- 캘린더 뷰, 월간 통계, 일별 합계 등에서 자주 사용되는 쿼리 패턴:
-- WHERE ledger_id = X AND date >= Y AND date <= Z

CREATE INDEX IF NOT EXISTS idx_transactions_ledger_id_date
ON transactions(ledger_id, date);
