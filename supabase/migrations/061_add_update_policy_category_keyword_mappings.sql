-- category_keyword_mappings UPDATE RLS 정책 추가
-- 생성자 본인 또는 가계부 owner/admin만 수정 가능
-- WITH CHECK으로 변경 후에도 동일 조건 충족 보장
CREATE POLICY "Users can update their own mappings"
  ON house.category_keyword_mappings
  FOR UPDATE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM house.ledger_members lm
      WHERE lm.ledger_id = category_keyword_mappings.ledger_id
      AND lm.user_id = auth.uid()
      AND lm.role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM house.ledger_members lm
      WHERE lm.ledger_id = category_keyword_mappings.ledger_id
      AND lm.user_id = auth.uid()
      AND lm.role IN ('owner', 'admin')
    )
  );
